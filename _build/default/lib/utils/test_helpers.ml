open Hardcaml.Signal

let sbox = [|
  0x63; 0x7c; 0x77; 0x7b; 0xf2; 0x6b; 0x6f; 0xc5; 0x30; 0x01; 0x67; 0x2b; 0xfe; 0xd7; 0xab; 0x76;
  0xca; 0x82; 0xc9; 0x7d; 0xfa; 0x59; 0x47; 0xf0; 0xad; 0xd4; 0xa2; 0xaf; 0x9c; 0xa4; 0x72; 0xc0;
  0xb7; 0xfd; 0x93; 0x26; 0x36; 0x3f; 0xf7; 0xcc; 0x34; 0xa5; 0xe5; 0xf1; 0x71; 0xd8; 0x31; 0x15;
  0x04; 0xc7; 0x23; 0xc3; 0x18; 0x96; 0x05; 0x9a; 0x07; 0x12; 0x80; 0xe2; 0xeb; 0x27; 0xb2; 0x75;
  0x09; 0x83; 0x2c; 0x1a; 0x1b; 0x6e; 0x5a; 0xa0; 0x52; 0x3b; 0xd6; 0xb3; 0x29; 0xe3; 0x2f; 0x84;
  0x53; 0xd1; 0x00; 0xed; 0x20; 0xfc; 0xb1; 0x5b; 0x6a; 0xcb; 0xbe; 0x39; 0x4a; 0x4c; 0x58; 0xcf;
  0xd0; 0xef; 0xaa; 0xfb; 0x43; 0x4d; 0x33; 0x85; 0x45; 0xf9; 0x02; 0x7f; 0x50; 0x3c; 0x9f; 0xa8;
  0x51; 0xa3; 0x40; 0x8f; 0x92; 0x9d; 0x38; 0xf5; 0xbc; 0xb6; 0xda; 0x21; 0x10; 0xff; 0xf3; 0xd2;
  0xcd; 0x0c; 0x13; 0xec; 0x5f; 0x97; 0x44; 0x17; 0xc4; 0xa7; 0x7e; 0x3d; 0x64; 0x5d; 0x19; 0x73;
  0x60; 0x81; 0x4f; 0xdc; 0x22; 0x2a; 0x90; 0x88; 0x46; 0xee; 0xb8; 0x14; 0xde; 0x5e; 0x0b; 0xdb;
  0xe0; 0x32; 0x3a; 0x0a; 0x49; 0x06; 0x24; 0x5c; 0xc2; 0xd3; 0xac; 0x62; 0x91; 0x95; 0xe4; 0x79;
  0xe7; 0xc8; 0x37; 0x6d; 0x8d; 0xd5; 0x4e; 0xa9; 0x6c; 0x56; 0xf4; 0xea; 0x65; 0x7a; 0xae; 0x08;
  0xba; 0x78; 0x25; 0x2e; 0x1c; 0xa6; 0xb4; 0xc6; 0xe8; 0xdd; 0x74; 0x1f; 0x4b; 0xbd; 0x8b; 0x8a;
  0x70; 0x3e; 0xb5; 0x66; 0x48; 0x03; 0xf6; 0x0e; 0x61; 0x35; 0x57; 0xb9; 0x86; 0xc1; 0x1d; 0x9e;
  0xe1; 0xf8; 0x98; 0x11; 0x69; 0xd9; 0x8e; 0x94; 0x9b; 0x1e; 0x87; 0xe9; 0xce; 0x55; 0x28; 0xdf;
  0x8c; 0xa1; 0x89; 0x0d; 0xbf; 0xe6; 0x42; 0x68; 0x41; 0x99; 0x2d; 0x0f; 0xb0; 0x54; 0xbb; 0x16
|]


(* ------------------------------------------------------------------ *)
(* Byte helpers with big-endian mapping                              *)
(* ------------------------------------------------------------------ *)
let from_bytes bytes = concat_msb bytes

let get_byte data idx =
  let hi = 127 - idx * 8 in
  select data hi (hi - 7)

(* ------------------------------------------------------------------ *)
(* S-boxes (forward & inverse)                                        *)
(* ------------------------------------------------------------------ *)

let inv_sbox =
  let t = Array.make 256 0 in
  Array.iteri (fun i v ->
    let idx = v land 0xFF in
    t.(idx) <- i
  ) sbox;
  t




let sbox_lookup byte =
  let tbl = Array.map (fun x -> of_int ~width:8 x) sbox in
  mux byte (Array.to_list tbl)

let inv_sbox_lookup byte =
  let tbl = Array.map (fun x -> of_int ~width:8 x) inv_sbox in
  mux byte (Array.to_list tbl)

let sub_bytes state =
  from_bytes (List.init 16 (fun i -> sbox_lookup (get_byte state i)))

let inv_sub_bytes state =
  from_bytes (List.init 16 (fun i -> inv_sbox_lookup (get_byte state i)))

let safe_nth lst i =
  match List.nth_opt lst i with
  | Some x -> x
  | None -> invalid_arg ("safe_nth: index " ^ Int.to_string i)

let shift_rows state =
  let b = List.init 16 (fun i -> get_byte state i) in
  from_bytes [
    (* Result: s0 s5 s10 s15 s4 s9 s14 s3 s8 s13 s2 s7 s12 s1 s6 s11 *)
    safe_nth b 0;  safe_nth b 5;  safe_nth b 10; safe_nth b 15;
    safe_nth b 4;  safe_nth b 9;  safe_nth b 14; safe_nth b 3;
    safe_nth b 8;  safe_nth b 13; safe_nth b 2;  safe_nth b 7;
    safe_nth b 12; safe_nth b 1;  safe_nth b 6;  safe_nth b 11;
  ]

let inv_shift_rows state =
  let b = List.init 16 (fun i -> get_byte state i) in
  from_bytes [
    (* Inverse of: s0 s5 s10 s15 s4 s9 s14 s3 s8 s13 s2 s7 s12 s1 s6 s11 *)
    (* Should give: s0 s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 s12 s13 s14 s15 *)
    safe_nth b 0;  safe_nth b 13; safe_nth b 10; safe_nth b 7;
    safe_nth b 4;  safe_nth b 1;  safe_nth b 14; safe_nth b 11;
    safe_nth b 8;  safe_nth b 5;  safe_nth b 2;  safe_nth b 15;
    safe_nth b 12; safe_nth b 9;  safe_nth b 6;  safe_nth b 3;
  ]

let xtime x =
  let shifted = sll x 1 in
  mux2 (msb x) (shifted ^: of_int ~width:(width x) 0x1B) shifted

let gf_mul x c =
  let c_bits = List.init 8 (fun i -> (c lsr i) land 1) in
  let rec loop acc p bits =
    match bits with
    | [] -> acc
    | bit :: rest ->
      let acc' = if bit <> 0 then acc ^: p else acc in
      loop acc' (xtime p) rest
  in
  loop (zero (width x)) x c_bits

let mix_column s0 s1 s2 s3 =
  let t0 = gf_mul s0 0x02 ^: gf_mul s1 0x03 ^: s2 ^: s3 in
  let t1 = s0 ^: gf_mul s1 0x02 ^: gf_mul s2 0x03 ^: s3 in
  let t2 = s0 ^: s1 ^: gf_mul s2 0x02 ^: gf_mul s3 0x03 in
  let t3 = gf_mul s0 0x03 ^: s1 ^: s2 ^: gf_mul s3 0x02 in
  [t0; t1; t2; t3]

let mix_columns state =
  let bytes = List.init 16 (fun i -> get_byte state i) in
  let cols = List.init 4 (fun c ->
    (* Column c is at positions c*4, c*4+1, c*4+2, c*4+3 (after ShiftRows) *)
    let idx = c * 4 in
    mix_column
      (safe_nth bytes idx)
      (safe_nth bytes (idx+1))
      (safe_nth bytes (idx+2))
      (safe_nth bytes (idx+3))
  ) in
  from_bytes (List.concat cols)

let inv_mix_columns state =
  let bytes = List.init 16 (fun i -> get_byte state i) in
  let cols = List.init 4 (fun c ->
    (* Column c is at positions c*4, c*4+1, c*4+2, c*4+3 (after InvShiftRows) *)
    let idx = c * 4 in
    let s0 = safe_nth bytes idx      in
    let s1 = safe_nth bytes (idx+1)  in
    let s2 = safe_nth bytes (idx+2)  in
    let s3 = safe_nth bytes (idx+3)  in
    let t0 = gf_mul s0 0x0E ^: gf_mul s1 0x0B ^: gf_mul s2 0x0D ^: gf_mul s3 0x09 in
    let t1 = gf_mul s0 0x09 ^: gf_mul s1 0x0E ^: gf_mul s2 0x0B ^: gf_mul s3 0x0D in
    let t2 = gf_mul s0 0x0D ^: gf_mul s1 0x09 ^: gf_mul s2 0x0E ^: gf_mul s3 0x0B in
    let t3 = gf_mul s0 0x0B ^: gf_mul s1 0x0D ^: gf_mul s2 0x09 ^: gf_mul s3 0x0E in
    [t0; t1; t2; t3]
  ) in
  from_bytes (List.concat cols)

let rcon = [| 0x01; 0x02; 0x04; 0x08; 0x10; 0x20; 0x40; 0x80; 0x1B; 0x36 |]

let rot_word w =
  let a = select w 31 24 in
  let b = select w 23 16 in
  let c = select w 15 8  in
  let d = select w 7  0  in
  concat_msb [b; c; d; a]

let sub_word w =
  let a = sbox_lookup (select w 31 24) in
  let b = sbox_lookup (select w 23 16) in
  let c = sbox_lookup (select w 15 8 ) in
  let d = sbox_lookup (select w 7  0 ) in
  concat_msb [a; b; c; d]

let key_expansion_step prev_key round =
  let w0 = select prev_key 127 96 in
  let w1 = select prev_key 95 64  in
  let w2 = select prev_key 63 32  in
  let w3 = select prev_key 31 0   in
  let rcon_byte = mux round (Array.to_list (Array.map (fun x -> of_int ~width:8 x) rcon)) in
  let rcon_val = concat_msb [rcon_byte; of_int ~width:24 0] in
  let temp = sub_word (rot_word w3) ^: rcon_val in
  let new_w0 = w0 ^: temp in
  let new_w1 = new_w0 ^: w1 in
  let new_w2 = new_w1 ^: w2 in
  let new_w3 = new_w2 ^: w3 in
  concat_msb [new_w0; new_w1; new_w2; new_w3]
