# Hardcaml-Cryptography-Library
HCL is an open-source, plug-and-play cryptography library for the Arty and Nexys boards using Hardcaml

# Architecture

┌─────────────────────────────────────┐
│         High-Level OCaml API        │  <- Tink-style safe interfaces
├─────────────────────────────────────┤
│      Hardcaml Circuit Library       │  <- Hardware implementations
├─────────────────────────────────────┤
│     Verified Primitive Cores        │  <- Formally verified components
├─────────────────────────────────────┤
│    FPGA Platform Abstraction        │  <- Xilinx/Intel/Lattice support
└─────────────────────────────────────┘

# Core Design Principles

-  Misuse-Resistant APIs: Like Tink, impossible to use incorrectly by design
-  Hardware-First: Algorithms chosen for FPGA acceleration benefits
-  Composable: Modular design allowing easy combination of primitives
-  Verifiable: Formal verification capabilities through Hardcaml's infrastructure

# MVP Deliverables

-  Core cryptographic circuits in Hardcaml
-  Type-safe OCaml bindings matching Tink's API style
-  Simulation test suite with known test vectors
-  Basic FPGA deployment examples (Xilinx/Intel)
-  Performance benchmarks vs. software implementations


# MVP Crypto Suite 
1. Block Ciphers
  - AES-128 (ECB/CBC/CTR modes)
  - ChaCha20

2. Digital Signatures 
  - ED25519

3. Hash Functions
  - SHA-256
  - BLAKE2s

4. Message Authentication
  - HMAC-SHA256
  - Poly1305

5. Random Numbers
  - LFSR-based PRNG
  - Ring Oscillator TRNG

# Future Roadmap

-  Homomorphic encryption primitives
-  Multi-party computation support
-  Cloud FPGA deployment (AWS F1, Azure NP)
