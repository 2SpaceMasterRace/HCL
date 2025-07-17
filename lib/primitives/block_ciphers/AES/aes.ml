open Hardcaml
open! Hardcaml.Always
module Helpers = Utils.Test_helpers

module I = struct
  type 'a t = {
    clock : 'a
    ;reset : 'a
    ;start : 'a
    ;mode : 'a
    ;key : 'a [@bits 128]
    ;data_in : 'a [@bits 128]
  } [@@deriving hardcaml]
end

module O = struct
  type 'a t = {
    data_out : 'a [@bits 128]
    ;done_ : 'a
    ;ready : 'a
  } [@@deriving hardcaml]
end

module State = struct
  type t = 
    | Idle
    | KeyExpansion
    | AddRoundKey
    | MainRounds
    | FinalRound
    | Done
  [@@deriving sexp_of, compare, enumerate]
end

let create (i : _ I.t) : _ O.t =
  let open Signal in
  let spec = Reg_spec.create ~clock:i.clock ~reset:i.reset () in
  
  let state_machine = Always.State_machine.create (module State) spec in
  let round_counter = Always.Variable.reg spec ~width:4 in
  let key_expansion_counter = Always.Variable.reg spec ~width:4 in
  let round_keys = Array.init 11 (fun _ -> Always.Variable.reg spec ~width:128) in
  let state_reg = Always.Variable.reg spec ~width:128 in
  let output_reg = Always.Variable.reg spec ~width:128 in
  let done_flag = Always.Variable.reg spec ~width:1 in
  let ready_flag = Always.Variable.reg spec ~width:1 in
  
  Always.(compile [
    done_flag <--. 0;
    
    state_machine.switch [
      Idle, [
        ready_flag <--. 1;
        when_ i.start [
          state_reg <-- i.data_in;
          round_keys.(0) <-- i.key;
          round_counter <--. 0;
          key_expansion_counter <--. 0;
          ready_flag <--. 0;
          state_machine.set_next KeyExpansion;
        ];
      ];
      
      KeyExpansion, (
        let counter = key_expansion_counter.value in
        let current_key = mux counter (Array.to_list (Array.map Always.Variable.value round_keys)) in
        let next_key = Helpers.key_expansion_step current_key counter in
        let next_idx = counter +:. 1 in
        [
          when_ (counter <:. 10) [
            (* Store next key at index counter+1 *)
            round_keys.(1) <-- (mux2 (counter ==:. 0) next_key round_keys.(1).value);
            round_keys.(2) <-- (mux2 (counter ==:. 1) next_key round_keys.(2).value);
            round_keys.(3) <-- (mux2 (counter ==:. 2) next_key round_keys.(3).value);
            round_keys.(4) <-- (mux2 (counter ==:. 3) next_key round_keys.(4).value);
            round_keys.(5) <-- (mux2 (counter ==:. 4) next_key round_keys.(5).value);
            round_keys.(6) <-- (mux2 (counter ==:. 5) next_key round_keys.(6).value);
            round_keys.(7) <-- (mux2 (counter ==:. 6) next_key round_keys.(7).value);
            round_keys.(8) <-- (mux2 (counter ==:. 7) next_key round_keys.(8).value);
            round_keys.(9) <-- (mux2 (counter ==:. 8) next_key round_keys.(9).value);
            round_keys.(10) <-- (mux2 (counter ==:. 9) next_key round_keys.(10).value);
            key_expansion_counter <-- next_idx;
          ];
          when_ (counter ==:. 10) [
            state_machine.set_next AddRoundKey;
          ];
        ]
      );

      AddRoundKey, [
        state_reg <-- (mux2 i.mode
          (state_reg.value ^: round_keys.(10).value)  
          (state_reg.value ^: round_keys.(0).value)   
        );
        round_counter <--. 1;
        state_machine.set_next MainRounds;
      ];
      
      MainRounds, (
        let round = round_counter.value in
        let current_state = state_reg.value in

        let enc_key_idx = round in
        let dec_key_idx = of_int ~width:4 10 -: round in

        let transformed = mux2 i.mode
          (* Decryption: InvShiftRows -> InvSubBytes -> AddRoundKey -> InvMixColumns *)
          (let inv_shift = Helpers.inv_shift_rows current_state in
           let inv_sub = Helpers.inv_sub_bytes inv_shift in
           let round_key = mux dec_key_idx (Array.to_list (Array.map Always.Variable.value round_keys)) in
           let add_key = inv_sub ^: round_key in
           Helpers.inv_mix_columns add_key)

          (* Encryption: SubBytes -> ShiftRows -> MixColumns -> AddRoundKey *)
          (let sub = Helpers.sub_bytes current_state in
           let shift = Helpers.shift_rows sub in
           let mix = Helpers.mix_columns shift in
           let round_key = mux enc_key_idx (Array.to_list (Array.map Always.Variable.value round_keys)) in
           mix ^: round_key)
        in
        
        [
          state_reg <-- transformed;
          round_counter <-- (round +:. 1);
          
          when_ (round ==:. 9) [
            state_machine.set_next FinalRound;
          ];
        ]
      );
      
      FinalRound, (
        let current_state = state_reg.value in
        
        let final_result = mux2 i.mode
          (* Decryption: InvShiftRows -> InvSubBytes -> AddRoundKey *)
          (let inv_shift = Helpers.inv_shift_rows current_state in
           let inv_sub = Helpers.inv_sub_bytes inv_shift in
           inv_sub ^: round_keys.(0).value)

          (* Encryption: SubBytes -> ShiftRows -> AddRoundKey *)
          (let sub = Helpers.sub_bytes current_state in
           let shift = Helpers.shift_rows sub in
           shift ^: round_keys.(10).value)
        in
        
        [
          output_reg <-- final_result;
          done_flag <--. 1;
          state_machine.set_next Done;
        ]
      );
      
      Done, [
        done_flag <--. 1;
        when_ (~:(i.start)) [
          state_machine.set_next Idle;
        ];
      ];
    ];
  ]);
  
  { O.
    data_out = output_reg.value;
    done_ = done_flag.value;
    ready = ready_flag.value;
  }

let circuit =
  let module C = Circuit.With_interface(I)(O) in
  C.create_exn ~name:"aes_128" create
