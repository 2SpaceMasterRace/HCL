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
    | InitialRound
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
  let round_keys = Array.init 11 (fun _ -> Always.Variable.reg spec ~width:128) in

  let state_reg = Always.Variable.reg spec ~width:128 in
  let output_reg = Always.Variable.reg spec ~width:128 in
  let done_flag = Always.Variable.reg spec ~width:1 in
  let ready_flag = Always.Variable.reg spec ~width:1 in
  
  let key_expansion_counter = Always.Variable.reg spec ~width:4 in
  
  Always.(compile [
    done_flag <--. 0;
    
    state_machine.switch [
      Idle, [
        ready_flag <--. 1;
        when_ i.start [
          round_counter <--. 0;
          key_expansion_counter <--. 0;
          state_reg <-- i.data_in;
          round_keys.(0) <-- i.key;
          ready_flag <--. 0;
          state_machine.set_next KeyExpansion;
        ];
      ];
      
      KeyExpansion, [
        let idx = key_expansion_counter.value in
        let prev_key = round_keys.(to_int idx).value in
        let next_key = Helpers.key_expansion_step prev_key idx in

        if_ (idx <:. 10)
          [ key_expansion_counter <-- idx +:. 1;
            round_keys.(to_int (idx +:. 1)) <-- next_key;
          ]
          [ when_ (idx ==:. 9) [
              state_machine.set_next InitialRound;
            ];
          ];
      ];

      InitialRound, [
        state_reg <-- (state_reg.value ^: round_keys.(0).value);
        round_counter <--. 1;
        state_machine.set_next MainRounds;
      ];
      
      MainRounds, (
        let round        = round_counter.value in
        let current_state = state_reg.value    in
        let round_key =
          mux round (Array.to_list (Array.map Always.Variable.value round_keys))
        in
        let transformed =
          mux2 i.mode
            (* encryption *)
            (let sub  = Helpers.sub_bytes current_state in
             let shift = Helpers.shift_rows sub in
             let mix   = Helpers.mix_columns shift in
             mix ^: round_key)

            (* decryption *)
            (let inv_shift = Helpers.inv_shift_rows current_state in
             let inv_sub   = Helpers.inv_sub_bytes inv_shift in
             let add_key   = inv_sub ^: round_key in
             Helpers.inv_mix_columns add_key)
        in
        [
          state_reg     <-- transformed;
          round_counter <-- (round +:. 1);
          when_ (round ==:. 9) [
            state_machine.set_next FinalRound
          ];
        ]
      );
      
      FinalRound, (
        let current_state = state_reg.value in
        let final_key = round_keys.(10).value in
        
        let final_result = 
          mux2 i.mode
            (* Decryption final round *)
            (let inv_shift = Helpers.inv_shift_rows current_state in
             let inv_sub = Helpers.inv_sub_bytes inv_shift in
             inv_sub ^: final_key)

            (* Encryption final round *)
            (let sub = Helpers.sub_bytes current_state in
             let shift = Helpers.shift_rows sub in
             shift ^: final_key)
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
