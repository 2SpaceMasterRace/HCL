open Core
open Hardcaml
open Hardcaml.Cyclesim
open Hardcaml.Waveterm

let test_vectors = [
  (* (key, plaintext, expected_ciphertext) *)
  ("00000000000000000000000000000000", 
   "00000000000000000000000000000000", 
   "66e94bd4ef8a2c3b884cfa59ca342b2e");
   
  ("2b7e151628aed2a6abf7158809cf4f3c",
   "6bc1bee22e409f96e93d7e117393172a",
   "3ad77bb40d7a3660a89ecaf32466ef97");
   
  ("2b7e151628aed2a6abf7158809cf4f3c",
   "ae2d8a571e03ac9c9eb76fac45af8e51",
   "f5d3d58503b9699de785895a96fdbaaf");
]

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

let test_encryption () =
  Printf.printf "=== Testing AES-128 Encryption ===\n";
  
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
  List.iter test_vectors ~f:(fun (key_hex, plaintext_hex, expected_hex) ->
    Printf.printf "\nTest vector:\n";
    Printf.printf "  Key:       %s\n" key_hex;
    Printf.printf "  Plaintext: %s\n" plaintext_hex;
    Printf.printf "  Expected:  %s\n" expected_hex;
    
    while Bits.to_int !(outputs.ready) = 0 do
      Cyclesim.cycle sim;
    done;
    
    inputs.key := hex_to_bits 128 key_hex;
    inputs.data_in := hex_to_bits 128 plaintext_hex;
    inputs.start := Bits.vdd;
    Cyclesim.cycle sim;
    inputs.start := Bits.gnd;
    
    let cycles = wait_for_done sim outputs 50 in
    Printf.printf "  Completed in %d cycles\n" cycles;
    let result = Bits.to_hex !(outputs.data_out) in
    Printf.printf "  Got:       %s\n" result;
    
    if String.(result = expected_hex) then
      Printf.printf "  ✓ PASS\n"
    else
      Printf.printf "  ✗ FAIL\n"
  )

let test_decryption () =
  Printf.printf "\n=== Testing AES-128 Decryption ===\n";
  
  let module Sim = Cyclesim.With_interface(Aes.I)(Aes.O) in
  let sim = Sim.create Aes.create in
  let inputs = Cyclesim.inputs sim in
  let outputs = Cyclesim.outputs sim in
  inputs.clock := Bits.vdd;
  inputs.reset := Bits.vdd;
  inputs.start := Bits.gnd;
  inputs.mode := Bits.vdd;

  Cyclesim.cycle sim;
  inputs.reset := Bits.gnd;
  List.iter test_vectors ~f:(fun (key_hex, expected_hex, ciphertext_hex) ->
    Printf.printf "\nDecryption test:\n";
    Printf.printf "  Key:        %s\n" key_hex;
    Printf.printf "  Ciphertext: %s\n" ciphertext_hex;
    Printf.printf "  Expected:   %s\n" expected_hex;
    
    while Bits.to_int !(outputs.ready) = 0 do
      Cyclesim.cycle sim;
    done;
    
    inputs.key := hex_to_bits 128 key_hex;
    inputs.data_in := hex_to_bits 128 ciphertext_hex;
    inputs.start := Bits.vdd;
    Cyclesim.cycle sim;
    inputs.start := Bits.gnd;
    let cycles = wait_for_done sim outputs 50 in
    let result = Bits.to_hex !(outputs.data_out) in
    Printf.printf "  Got:        %s\n" result;
    Printf.printf "  Cycles:     %d\n" cycles;
    
    if String.(result = expected_hex) then
      Printf.printf "  ✓ PASS\n"
    else
      Printf.printf "  ✗ FAIL\n"
  )

let test_with_waveform () =
  Printf.printf "\n=== Generating Waveform ===\n";
  
  let module Sim = Cyclesim.With_interface(Aes.I)(Aes.O) in
  let sim = Sim.create Aes.create in
  let waves, sim = Waveform.create sim in
  
  let inputs = Cyclesim.inputs sim in
  let outputs = Cyclesim.outputs sim in
  
  inputs.clock := Bits.vdd;
  inputs.reset := Bits.vdd;
  inputs.mode := Bits.gnd;
  Cyclesim.cycle sim;
  inputs.reset := Bits.gnd;
  
  let key = "2b7e151628aed2a6abf7158809cf4f3c" in
  let plaintext = "6bc1bee22e409f96e93d7e117393172a" in
  
  inputs.key := hex_to_bits 128 key;
  inputs.data_in := hex_to_bits 128 plaintext;
  inputs.start := Bits.vdd;
  Cyclesim.cycle sim;
  inputs.start := Bits.gnd;
  
  for _ = 1 to 30 do
    Cyclesim.cycle sim;
  done;
  
  Waveform.print ~wave_width:80 ~display_height:40 waves;
  
  let vcd = Vcd.create "aes_waveform.vcd" in
  Waveform.write_vcd waves vcd;
  Vcd.close vcd;
  Printf.printf "Waveform saved to aes_waveform.vcd\n"

let test_performance () =
  Printf.printf "\n=== Performance Test ===\n";
  
  let module Sim = Cyclesim.With_interface(Aes.I)(Aes.O) in
  let sim = Sim.create Aes.create in
  let inputs = Cyclesim.inputs sim in
  let outputs = Cyclesim.outputs sim in
  
  inputs.clock := Bits.vdd;
  inputs.reset := Bits.vdd;
  inputs.mode := Bits.gnd;
  Cyclesim.cycle sim;
  inputs.reset := Bits.gnd;
  
  let start_time = Unix.gettimeofday () in
  let num_blocks = 1000 in
  
  for i = 0 to num_blocks - 1 do
    while Bits.to_int !(outputs.ready) = 0 do
      Cyclesim.cycle sim;
    done;
    
    inputs.key := Bits.random ~width:128;
    inputs.data_in := Bits.random ~width:128;
    inputs.start := Bits.vdd;
    Cyclesim.cycle sim;
    inputs.start := Bits.gnd;
    
    let _ = wait_for_done sim outputs 50 in
    ()
  done;
  
  let end_time = Unix.gettimeofday () in
  let elapsed = end_time -. start_time in
  let blocks_per_sec = Float.of_int num_blocks /. elapsed in
  
  Printf.printf "Processed %d blocks in %.3f seconds\n" num_blocks elapsed;
  Printf.printf "Throughput: %.0f blocks/second\n" blocks_per_sec;
  Printf.printf "100MHz clock: %.2f Gbps\n" 
    (blocks_per_sec *. 128.0 /. 1e9 *. 100e6 /. blocks_per_sec)

let () =
  test_encryption ();
  test_decryption ();
  test_with_waveform ();
  test_performance ()
