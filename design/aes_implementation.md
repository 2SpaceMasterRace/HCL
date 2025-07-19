# AES-128 Implementation in Hardcaml

## Table of Contents
1. [Introduction](#introduction)
2. [Architecture Overview](#architecture-overview)
3. [Core Components](#core-components)
4. [The State Machine](#the-state-machine)
5. [Key Expansion Process](#key-expansion-process)
6. [Round Transformations](#round-transformations)
7. [Hardware Generation](#hardware-generation)
8. [Performance Analysis](#performance-analysis)
9. [Design Decisions](#design-decisions)

## Introduction

This document provides a comprehensive explanation of an AES-128 encryption/decryption module implemented in Hardcaml. The implementation demonstrates how high-level functional programming concepts translate into efficient hardware circuits, creating a cryptographic accelerator capable of processing data at hundreds of megabits per second.

The design implements the complete AES-128 algorithm, supporting both encryption and decryption modes in a single module. It uses a finite state machine to orchestrate the various stages of the algorithm while leveraging Hardcaml's ability to generate complex combinational circuits for the core cryptographic operations.

## Architecture Overview

The AES module follows a classic hardware design pattern with clearly defined interfaces and internal state management. The architecture consists of several key elements working in harmony:

The module accepts a 128-bit key and 128-bit data block, along with control signals for clock, reset, start, and mode selection. It produces a 128-bit output along with status flags indicating completion and readiness. Internally, the design maintains registers for storing intermediate states, round keys, and control information.

```
┌─────────────────────────────────────────────┐
│                AES-128 Module               │
│  ┌────────┐  ┌──────────┐  ┌────────────┐ │
│  │ Input  │  │  State   │  │   Output   │ │
│  │ Ports  │  │ Machine  │  │   Ports    │ │
│  └────┬───┘  └────┬─────┘  └──────┬─────┘ │
│       │           │                │        │
│  ┌────▼───────────▼────────────────▼─────┐ │
│  │          Internal Registers           │ │
│  │  • state_reg (128-bit)               │ │
│  │  • round_keys[0..10] (11×128-bit)    │ │
│  │  • counters (4-bit each)             │ │
│  └───────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

## Core Components

### Interface Definitions

The input interface captures all signals needed to control the AES module:

```ocaml
module I = struct
  type 'a t = {
    clock : 'a              (* System clock for synchronous operation *)
    ;reset : 'a             (* Asynchronous reset signal *)
    ;start : 'a             (* Pulse to begin operation *)
    ;mode : 'a              (* 0 = encrypt, 1 = decrypt *)
    ;key : 'a [@bits 128]   (* Encryption/decryption key *)
    ;data_in : 'a [@bits 128] (* Input data block *)
  } [@@deriving hardcaml]
end
```

The output interface provides the result and status information:

```ocaml
module O = struct
  type 'a t = {
    data_out : 'a [@bits 128]  (* Encrypted/decrypted result *)
    ;done_ : 'a                (* Operation complete flag *)
    ;ready : 'a                (* Ready for new operation *)
  } [@@deriving hardcaml]
end
```

### State Machine Definition

The finite state machine controls the overall flow of the AES algorithm:

```ocaml
module State = struct
  type t =
    | Idle          (* Waiting for start signal *)
    | KeyExpansion  (* Generating round keys *)
    | AddRoundKey   (* Initial key whitening *)
    | MainRounds    (* Rounds 1-9 *)
    | FinalRound    (* Round 10 (no MixColumns) *)
    | Done          (* Operation complete *)
end
```

This state machine ensures proper sequencing of operations while maintaining deterministic timing. Each state represents a distinct phase of the AES algorithm, with transitions occurring based on counters and completion conditions.

### Register Architecture

The implementation uses several registers to maintain state between clock cycles:

```ocaml
let state_machine = Always.State_machine.create (module State) spec in
let round_counter = Always.Variable.reg spec ~width:4 in
let key_expansion_counter = Always.Variable.reg spec ~width:4 in
let round_keys = Array.init 11 (fun _ -> Always.Variable.reg spec ~width:128) in
let state_reg = Always.Variable.reg spec ~width:128 in
let output_reg = Always.Variable.reg spec ~width:128 in
let done_flag = Always.Variable.reg spec ~width:1 in
let ready_flag = Always.Variable.reg spec ~width:1 in
```


## The State Machine

### Idle State

The Idle state represents the module's resting condition, waiting for new work:

```ocaml
Idle, [
  ready_flag <--. 1;  (* Signal readiness for new operation *)
  when_ i.start [
    state_reg <-- i.data_in;        (* Capture input data *)
    round_keys.(0) <-- i.key;       (* Store original key *)
    round_counter <--. 0;           (* Reset round counter *)
    key_expansion_counter <--. 0;   (* Reset key expansion counter *)
    ready_flag <--. 0;              (* Clear ready flag *)
    state_machine.set_next KeyExpansion;  (* Begin key expansion *)
  ];
];
```

When the start signal arrives, the module captures the input data and key, resets all counters, and transitions to key expansion. This single-cycle setup ensures minimal latency between request and processing.

### Key Expansion State

The KeyExpansion state generates all round keys needed for the AES algorithm. This process takes 11 clock cycles, generating one new key per cycle:

```ocaml
KeyExpansion, (
  let counter = key_expansion_counter.value in
  let current_key = mux counter (Array.to_list (Array.map Always.Variable.value round_keys)) in
  let next_key = Helpers.key_expansion_step current_key counter in
  let next_idx = counter +:. 1 in
  [
    when_ (counter <:. 10) [
      (* Store next_key in the appropriate round_keys register *)
      round_keys.(1) <-- (mux2 (counter ==:. 0) next_key round_keys.(1).value);
      round_keys.(2) <-- (mux2 (counter ==:. 1) next_key round_keys.(2).value);
      (* ... continues for all 11 keys ... *)
      key_expansion_counter <-- next_idx;
    ];
    when_ (counter ==:. 10) [
      state_machine.set_next AddRoundKey;
    ];
  ]
);
```

The unrolled assignment pattern (round_keys.(1) <-- ..., round_keys.(2) <-- ..., etc.) is necessary because hardware cannot support dynamic array indexing. Each assignment creates a multiplexer that conditionally updates one specific register based on the counter value.

### AddRoundKey State

This state performs the initial key whitening operation, which differs between encryption and decryption:

```ocaml
AddRoundKey, [
  state_reg <-- (mux2 i.mode
    (state_reg.value ^: round_keys.(10).value)  (* Decryption uses last key *)
    (state_reg.value ^: round_keys.(0).value)   (* Encryption uses first key *)
  );
  round_counter <--. 1;
  state_machine.set_next MainRounds;
];
```

The mode-based multiplexer ensures that encryption and decryption follow their respective key schedules - encryption starts with round_keys[0] and proceeds forward, while decryption starts with round_keys[10] and proceeds backward.

### MainRounds State

The MainRounds state implements the core AES rounds 1 through 9. Each round applies the four main AES operations in the appropriate order:

```ocaml
MainRounds, (
  let round = round_counter.value in
  let current_state = state_reg.value in
  
  let enc_key_idx = round in
  let dec_key_idx = of_int ~width:4 10 -: round in
  
  let transformed = mux2 i.mode
    (* Decryption pipeline *)
    (let inv_shift = Helpers.inv_shift_rows current_state in
     let inv_sub = Helpers.inv_sub_bytes inv_shift in
     let round_key = mux dec_key_idx (Array.to_list (Array.map Always.Variable.value round_keys)) in
     let add_key = inv_sub ^: round_key in
     Helpers.inv_mix_columns add_key)
     
    (* Encryption pipeline *)
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
```

Both encryption and decryption pipelines exist simultaneously in the hardware. The mode signal selects which result to use. This approach, while using more silicon area, ensures consistent timing regardless of the operation mode.

### FinalRound State

The tenth and final round omits the MixColumns operation, as specified by the AES standard:

```ocaml
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
```

### Done State

The Done state maintains the completion signal until the external system acknowledges it:

```ocaml
Done, [
  done_flag <--. 1;
  when_ (~:(i.start)) [
    state_machine.set_next Idle;
  ];
];
```

## Key Expansion Process

The key expansion algorithm generates 10 additional round keys from the original 128-bit key. Each new key depends on the previous key, creating a sequential dependency that requires 11 clock cycles to complete.

The expansion process for each round key follows these steps:

1. Extract the last word (32 bits) from the previous key
2. Rotate the word left by 8 bits (RotWord)
3. Apply S-box substitution to each byte (SubWord)
4. XOR with a round constant
5. XOR this result with the first word of the previous key
6. Generate remaining words through cascading XORs

For example, generating round_keys[1] from round_keys[0]:

```
Original key: 2B7E1516_28AED2A6_ABF71588_09CF4F3C

Step 1: Extract w3 = 09CF4F3C
Step 2: RotWord(w3) = CF4F3C09
Step 3: SubWord(CF4F3C09) = 8A84EB01
Step 4: XOR with Rcon[0] = 01000000
        Result: 8B84EB01
Step 5: new_w0 = 2B7E1516 XOR 8B84EB01 = A0FAFE17
Step 6: new_w1 = A0FAFE17 XOR 28AED2A6 = 88542CB1
        new_w2 = 88542CB1 XOR ABF71588 = 23A33939
        new_w3 = 23A33939 XOR 09CF4F3C = 2A6C7605

Round key 1: A0FAFE17_88542CB1_23A33939_2A6C7605
```

## Round Transformations

Each AES round (except the final one) consists of four transformations applied in sequence. The hardware implements these as combinational circuits, allowing all operations within a round to complete in a single clock cycle.

### SubBytes Transformation

SubBytes provides non-linearity through S-box substitution. The implementation creates 16 parallel S-box lookup circuits:

```ocaml
let sub_bytes state =
  from_bytes (List.init 16 (fun i -> sbox_lookup (get_byte state i)))
```

Each S-box is implemented as a 256-to-1 multiplexer or lookup table, depending on synthesis tool optimization. All 16 bytes are transformed simultaneously.

### ShiftRows Transformation

ShiftRows performs byte rotation within rows of the state matrix. This operation requires no logic gates - only rewiring:

```
Input matrix:          After ShiftRows:
 0  1  2  3            0  5 10 15
 4  5  6  7     →      4  9 14  3
 8  9 10 11            8 13  2  7
12 13 14 15           12  1  6 11
```

### MixColumns Transformation

MixColumns provides diffusion by mixing bytes within each column using matrix multiplication in GF(2^8):

```ocaml
let mix_column s0 s1 s2 s3 =
  let t0 = gf_mul s0 0x02 ^: gf_mul s1 0x03 ^: s2 ^: s3 in
  let t1 = s0 ^: gf_mul s1 0x02 ^: gf_mul s2 0x03 ^: s3 in
  let t2 = s0 ^: s1 ^: gf_mul s2 0x02 ^: gf_mul s3 0x03 in
  let t3 = gf_mul s0 0x03 ^: s1 ^: s2 ^: gf_mul s3 0x02 in
  [t0; t1; t2; t3]
```

The Galois field multiplications are implemented using the xtime operation (multiplication by 2) and XOR operations. Each column transformation requires 4 xtime operations and 12 XOR operations.

### AddRoundKey Transformation

AddRoundKey XORs the state with the appropriate round key. This operation provides the cryptographic connection between the key and the data.

## Hardware Generation

When Hardcaml compiles this design, it generates a complex network of digital circuits:

### Critical Path Analysis

The longest combinational path typically occurs in the MainRounds state through the MixColumns operation. This path includes:

1. State register output
2. SubBytes transformation (S-box lookup)
3. ShiftRows (wire routing only)
4. MixColumns (multiple xtime and XOR operations)
5. AddRoundKey (XOR operation)
6. Multiplexer for mode selection
7. State register input

The maximum operating frequency depends on this critical path delay plus setup/hold times of the registers.

## Performance Analysis

### Timing Characteristics

The implementation requires exactly 23 clock cycles per 128-bit block:

- 1 cycle: Idle to KeyExpansion transition
- 11 cycles: Key expansion (generating round_keys[1] through [10])
- 1 cycle: AddRoundKey (initial key whitening)
- 9 cycles: MainRounds (rounds 1-9)
- 1 cycle: FinalRound (round 10)

### Throughput Calculation

At a 100 MHz clock frequency:
- Time per block: 23 cycles × 10 ns/cycle = 230 ns
- Blocks per second: 1 / 230 ns ≈ 4.35 million
- Throughput: 4.35 M × 128 bits = 556 Mbps

This throughput remains constant regardless of encryption or decryption mode, providing predictable performance for system design.

### Latency Considerations

The 23-cycle latency is fixed and deterministic, making this implementation suitable for real-time applications. The initial 12-cycle overhead (key expansion + initial AddRoundKey) occurs only once per key, so consecutive blocks with the same key require only 11 cycles each (9 MainRounds + 1 FinalRound + 1 Done/Idle transition).

## Design Decisions

### Pre-computed Round Keys

Storing all round keys requires significant silicon area but provides several benefits:
- Simplified round logic (no key generation during rounds)
- Consistent timing for all rounds
- Easy support for both encryption and decryption
- Potential for pipelined implementations

### Parallel Encryption/Decryption Paths

Creating separate circuits for encryption and decryption with multiplexer selection ensures:
- Consistent timing regardless of mode
- Simplified control logic
- No performance penalty for mode switching

### Unrolled Array Updates

The explicit pattern for updating round keys addresses hardware synthesis limitations:
```ocaml
round_keys.(1) <-- (mux2 (counter ==:. 0) next_key round_keys.(1).value);
round_keys.(2) <-- (mux2 (counter ==:. 1) next_key round_keys.(2).value);
```

This approach creates predictable, synthesizable hardware at the cost of code verbosity (also not because I spent 6 hours debugging this and had to take this shortcut).

### State Machine Architecture

The six-state FSM provides clear separation of concerns:
- Each state has a single responsibility
- Transitions are simple and predictable
- Debugging and verification are straightforward
- Future enhancements (like pipelining) are easier to implement
