# Hardcaml-Cryptography-Library
HCL is an open-source, plug-and-play cryptography library for the Arty and Nexys boards for Hardcaml

# Instructions 
Only AES is implemented as of yet. You can find the implementation of AES at :
```bash
/lib/primitives/block_ciphers/AES/aes.ml
```
and the helper functions can be found at :
```bash
/lib/utils/test_helpers.ml
```
CLI is not implemented yet. To check encryption and decryption, head over to 
```bash
test/test_primitives/test_block_ciphers/test_aes
```
and head to EOF to find the test cases and modify them to your use-case.


To execute the program, just write the following command in your terminal:
```ocaml
dune exec hcl_main simulate
```

You can also verify through this [neat tool](http://aes.online-domain-tools.com/).


# Architecture

| Architecture Component           | Description                          |
|----------------------------------|--------------------------------------|
| High-Level OCaml API             | <-- Tink-style safe interfaces       |
| Hardcaml Circuit Library         | <-- Hardware implementations         |
| Verified Primitive Cores         | <-- Formally verified components     |
| FPGA                             | <-- Xilinx/Intel/Lattice support     |


# Core Design Principles

-  **Misuse-Resistant APIs**: Like Tink, impossible to use incorrectly by design
-  **Hardware-First**: Algorithms chosen for FPGA acceleration benefits
-  **Composable**: Modular design allowing easy combination of primitives
-  **Verifiable**: Formal verification capabilities through Hardcaml's infrastructure


# MVP Crypto Suite 
1. **Block Ciphers**
- [x] AES-128 (ECB mode only)
- [ ] ChaCha20

2. Digital Signatures
- [ ] ED25519

3. Hash Functions
- [ ] SHA-256
- [ ] BLAKE2s

4. Message Authentication
- [ ] HMAC-SHA256
- [ ] Poly1305
      
5. Random Numbers
- [ ] LFSR-based PRNG
- [ ] Ring Oscillator TRNG


# Roadmap

- [ ] Core cryptographic circuits in Hardcaml
- [ ] Simulation test suite with known test vectors
- [ ] Basic FPGA deployment examples (Xilinx/Intel)
- [ ] Performance benchmarks vs. software implementations
- [ ] Homomorphic encryption primitives
- [ ] Multi-party computation support
- [ ] Cloud FPGA deployment (AWS F1, Azure NP)

# References 

- [CryptoHack – Courses](https://cryptohack.org/courses/)
- [MIT 6.875 - Foundations of Cryptography](http://mit6875.org/)
- [Understanding Cryptography by Christof Paar - Book](https://www.cryptography-textbook.com/book/#toc)
- [Introduction to Cryptography by Christof Paar – YouTube](https://www.youtube.com/@introductiontocryptography4223/videos)
