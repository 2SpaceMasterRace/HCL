open Hardcaml
open Hardcaml.Signal

let test_key_expansion () =
  let key = Bits.of_hex ~width:128 "2b7e151628aed2a6abf7158809cf4f3c" in
  let round = of_int ~width:4 0 in
  
  (* Test key expansion step *)
  let result = Utils.Test_helpers.key_expansion_step key round in
  let hex_result = Hardcaml.Constant.to_hex_string ~signedness:Unsigned (Bits.to_constant result) in
  Printf.printf "Key expansion result: %s\n" hex_result;
  Printf.printf "Expected:            a0fafe1788542cb123a339392a6c7605\n"

let () = test_key_expansion ()