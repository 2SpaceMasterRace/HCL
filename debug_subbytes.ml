open Hardcaml
open Hardcaml.Signal

(* Test S-box with known values *)
let test_sbox () =
  let test_byte = of_int ~width:8 0x00 in
  let result = Utils.Test_helpers.sbox_lookup test_byte in
  let hex_result = Constant.to_hex_string ~signedness:Unsigned (Bits.to_constant result) in
  Printf.printf "S-box[0x00] = %s (expected: 63)\n" hex_result;
  
  let test_byte = of_int ~width:8 0x01 in
  let result = Utils.Test_helpers.sbox_lookup test_byte in
  let hex_result = Constant.to_hex_string ~signedness:Unsigned (Bits.to_constant result) in
  Printf.printf "S-box[0x01] = %s (expected: 7c)\n" hex_result;

(* Test SubBytes on all zeros *)
let test_subbytes () =
  let zeros = Bits.zero 128 in
  let result = Utils.Test_helpers.sub_bytes zeros in
  let hex_result = Constant.to_hex_string ~signedness:Unsigned (Bits.to_constant result) in
  Printf.printf "SubBytes(all zeros) = %s\n" hex_result;
  Printf.printf "Expected:            63636363636363636363636363636363\n"

let () = 
  test_sbox ();
  test_subbytes ()