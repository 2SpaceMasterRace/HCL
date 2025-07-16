open Hardcaml
open Hardcaml.Signal
open! Hardcaml.Always
module Helpers = Aes_helpers

module I = struct
  type 'a t = {
    clock : 'a
    ;reset : 'a
    ;start : 'a
    ;mode : 'a
    ;key : 'a [@bits 128]
    ;data_in : 'a [@bits 128]
  } [@@deriving sexp_of, hardcaml]
end

(* Output interface *)
module O = struct
  type 'a t = {
    data_out : 'a [@bits 128]
    ;done_ : 'a
    ;ready : 'a                   
  } [@@deriving sexp_of, hardcaml]
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
  
  let get_byte data idx = 
    (* if idx = 0, end bit would be 7, 1 - 8, 2 - 5*)
    select data ((idx + 1) * 8 - 1) (idx * 8) 
  in
  
  (* Create 128-bit value from bytes *)
  let from_bytes b15 b14 b13 b12 b11 b10 b9 b8 b7 b6 b5 b4 b3 b2 b1 b0 =
    concat_msb [b15; b14; b13; b12; b11; b10; b9; b8; b7; b6; b5; b4; b3; b2; b1; b0]
  in
  
  Always.(compile [
    done_flag <--. 0;
    
    sm.switch [
      Idle, [
        ready_flag <--. 1;
        when_ i.start [
          round_counter <--. 0;
          key_exp_counter <--. 0;
          state_reg <-- i.data_in;
          round_keys.(0) <-- i.key;
          ready_flag <--. 0;
          sm.set_next KeyExpansion;
        ];
      ];
      
      (* Key expansion state *)
      KeyExpansion, [
        let idx = key_exp_counter.value in
        let prev_key = round_keys.(to_int idx).value in
        
        (* Perform one step of key expansion *)
        let next_key = Helpers.key_expansion_step prev_key idx in
        when_ (idx <:. 10) [
          key_exp_counter <-- idx +:. 1;
          round_keys.(to_int (idx +:. 1)) <-- next_key;
        ] @@ [
          when_ (idx ==:. 9) [
            sm.set_next InitialRound;
          ];
        ];
      ];
      
      (* Initial round - just AddRoundKey *)
      InitialRound, [
        state_reg <-- (state_reg.value ^: round_keys.(0).value);
        round_counter <--. 1;
        sm.set_next MainRounds;
      ];
      
      (* Main rounds (1-9 for AES-128) *)
      MainRounds, [
        let round = round_counter.value in
        let current_state = state_reg.value in
        let round_key = mux round (Array.to_list (Array.map (fun k -> k.value) round_keys)) in
        
        (* Transform pipeline for encryption or decryption *)
        let transformed = 
          if_then_else i.mode
            (* Decryption *)
            (let inv_shift = Helpers.inv_shift_rows current_state in
             let inv_sub = Helpers.inv_sub_bytes inv_shift in
             let add_key = inv_sub ^: round_key in
             let inv_mix = Helpers.inv_mix_columns add_key in
             inv_mix)
            (* Encryption *)
            (let sub = Helpers.sub_bytes current_state in
             let shift = Helpers.shift_rows sub in
             let mix = Helpers.mix_columns shift in
             let add_key = mix ^: round_key in
             add_key)
        in
        
        state_reg <-- transformed;
        round_counter <-- round +:. 1;
        
        when_ (round ==:. 9) [
          sm.set_next FinalRound;
        ];
      ];
      
      (* Final round - no MixColumns *)
      FinalRound, [
        let current_state = state_reg.value in
        let final_key = round_keys.(10).value in
        
        let final_result = 
          if_then_else i.mode
            (* Decryption final round *)
            (let inv_shift = Helpers.inv_shift_rows current_state in
             let inv_sub = Helpers.inv_sub_bytes inv_shift in
             inv_sub ^: final_key)
            (* Encryption final round *)
            (let sub = Helpers.sub_bytes current_state in
             let shift = Helpers.shift_rows sub in
             shift ^: final_key)
        in
        
        output_reg <-- final_result;
        done_flag <--. 1;
        sm.set_next Done;
      ];
      
      (* Done state - hold output *)
      Done, [
        done_flag <--. 1;
        when_ (~: i.start) [
          sm.set_next Idle;
        ];
      ];
    ];
  ]);
  
  (* Create output *)
  { O.
    data_out = output_reg.value;
    done_ = done_flag.value;
    ready = ready_flag.value;
  }

(* Create the circuit *)
let circuit =
  let module C = Circuit.With_interface(I)(O) in
  C.create_exn ~name:"aes_128" create
