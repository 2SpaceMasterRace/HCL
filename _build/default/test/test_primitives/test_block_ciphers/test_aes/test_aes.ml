open Core
open Hardcaml

let hex_to_bits width hex_str =
  Bits.of_hex ~width hex_str

let wait_for_done sim outputs max_cycles =
  let rec loop n =
    if n > max_cycles then
      failwith "Timeout waiting for done signal"
    else if Bits.to_int !(outputs.Aes.O.done_) = 1 then
      n
    else begin
      Cyclesim.cycle sim;
      loop (n + 1)
    end
  in
  loop 0

(* ------------------------------------------------------------ *)
(* Single encryption test                                       *)
(* ------------------------------------------------------------ *)

let test_encrypt (name, key_hex, pt_hex, ct_hex) =
  Printf.printf "=== %s ===\n" name;
  let module Sim = Cyclesim.With_interface(Aes.I)(Aes.O) in
  let sim = Sim.create Aes.create in
  let inputs = Cyclesim.inputs sim in
  let outputs = Cyclesim.outputs sim in

  inputs.clock := Bits.vdd;
  inputs.reset := Bits.vdd;
  inputs.start := Bits.gnd;
  inputs.mode := Bits.gnd;
  inputs.key := Bits.zero 128;
  inputs.data_in := Bits.zero 128;
  Cyclesim.cycle sim;
  inputs.reset := Bits.gnd;

  Printf.printf "  Key:       %s\n" key_hex;
  Printf.printf "  Plaintext: %s\n" pt_hex;
  Printf.printf "  Expected:  %s\n" ct_hex;

  while Bits.to_int !(outputs.ready) = 0 do Cyclesim.cycle sim done;

  inputs.key := hex_to_bits 128 key_hex;
  inputs.data_in := hex_to_bits 128 pt_hex;
  inputs.start := Bits.vdd;
  Cyclesim.cycle sim;
  inputs.start := Bits.gnd;

  let cycles = wait_for_done sim outputs 100 in
  Printf.printf "  Completed in %d cycles\n" cycles;

  let got = Constant.to_hex_string ~signedness:Unsigned (Bits.to_constant !(outputs.data_out)) in
  Printf.printf "  Got:       %s\n" got;
  let pass = String.(got = ct_hex) in
  Printf.printf "  %s\n" (if pass then "✓ PASS" else "✗ FAIL");
  pass


(* ------------------------------------------------------------ *)
(* Single decryption test                                       *)
(* ------------------------------------------------------------ *)

let test_decrypt (name, key_hex, ct_hex, pt_hex) =
  Printf.printf "=== %s (decrypt) ===\n" name;
  let module Sim = Cyclesim.With_interface(Aes.I)(Aes.O) in
  let sim = Sim.create Aes.create in
  let inputs = Cyclesim.inputs sim in
  let outputs = Cyclesim.outputs sim in

  inputs.clock := Bits.vdd;
  inputs.reset := Bits.vdd;
  inputs.start := Bits.gnd;
  inputs.mode := Bits.vdd;
  inputs.key := Bits.zero 128;
  inputs.data_in := Bits.zero 128;
  Cyclesim.cycle sim;
  inputs.reset := Bits.gnd;

  Printf.printf "  Key:        %s\n" key_hex;
  Printf.printf "  Ciphertext: %s\n" ct_hex;
  Printf.printf "  Expected:   %s\n" pt_hex;

  while Bits.to_int !(outputs.ready) = 0 do Cyclesim.cycle sim done;

  inputs.key := hex_to_bits 128 key_hex;
  inputs.data_in := hex_to_bits 128 ct_hex;
  inputs.start := Bits.vdd;
  Cyclesim.cycle sim;
  inputs.start := Bits.gnd;

  let cycles = wait_for_done sim outputs 100 in
  Printf.printf "  Completed in %d cycles\n" cycles;

  let got = Constant.to_hex_string ~signedness:Unsigned (Bits.to_constant !(outputs.data_out)) in
  Printf.printf "  Got:        %s\n" got;
  let pass = String.(got = pt_hex) in
  Printf.printf "  %s\n" (if pass then "✓ PASS" else "✗ FAIL");
  pass


(* ------------------------------------------------------------ *)
(* Run all tests                                                *)
(* ------------------------------------------------------------ *)
let () =
  Printf.printf "Running AES Tests...\n\n";

  let test1 = test_encrypt ("All zeros test",
                            "00000000000000000000000000000000",
                            "00000000000000000000000000000000",
                            "66e94bd4ef8a2c3b884cfa59ca342b2e") in

  let test2 = test_encrypt ("Pattern test",
                            "0f0e0d0c0b0a09080706050403020100",
                            "0123456789abcdef0123456789abcdef",
                            "0823e07978c302802f9ced011d1c1442") in

  let test3 = test_encrypt ("Incremental test",
                            "000102030405060708090a0b0c0d0e0f",
                            "101112131415161718191a1b1c1d1e1f",
                            "07feef74e1d5036e900eee118e949293") in

  let test4 = test_decrypt ("All zeros test",
                            "00000000000000000000000000000000",
                            "66e94bd4ef8a2c3b884cfa59ca342b2e",
                            "00000000000000000000000000000000") in

  let test5 = test_decrypt ("Pattern test",
                            "0f0e0d0c0b0a09080706050403020100",
                            "0823e07978c302802f9ced011d1c1442",
                            "0123456789abcdef0123456789abcdef") in

  let test6 = test_decrypt ("Incremental test",
                            "000102030405060708090a0b0c0d0e0f",
                            "07feef74e1d5036e900eee118e949293",
                            "101112131415161718191a1b1c1d1e1f") in

  let all_ok = test1 && test2 && test3 && test4 && test5 && test6 in
  Printf.printf "\n=== Summary ===\n";
  Printf.printf "Overall: %s\n"
    (if all_ok then "ALL TESTS PASS" else "SOME TESTS FAIL")
