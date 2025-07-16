(* bin/main.ml *)
open Core
open Hardcaml
open Aes

let generate language =
  let module C = Circuit.With_interface (Aes.I) (Aes.O) in
  let circuit = C.create_exn ~name:"aes_128" Aes.create in
  Rtl.print language circuit

let simulate () =
  let _exit_status =
    Core_unix.system
      "dune exec test/test_primitives/test_block_ciphers/test_aes/test_aes.exe"
  in
  ()

let cmd_generate rtl =
  Command.basic
    ~summary:
      ("Generate " ^
       match rtl with
       | Rtl.Language.Verilog -> "Verilog"
       | Vhdl -> "VHDL")
    [%map_open.Command
      let () = return () in
      fun () -> generate rtl]

let cmd_simulate =
  Command.basic
    ~summary:"Run AES-128 encryption/decryption tests"
    [%map_open.Command
      let () = return () in
      fun () -> simulate ()]

let () =
  Command_unix.run
    (Command.group
       ~summary:"AES-128 Hardcaml demo: generate RTL or simulate"
       [ "simulate", cmd_simulate
       ; "verilog",  cmd_generate Verilog
       ; "vhdl",     cmd_generate Vhdl ])
