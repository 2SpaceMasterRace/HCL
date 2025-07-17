# Changelog

All notable changes to the **HCL (Hardcaml Crypto Library)** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- AES-128 block-cipher core (`HCL.aes`) with:
  - Single-clock, 10-round pipeline
  - Encryption & decryption modes
  - Integrated key-expansion state-machine
- CLI front-end (`main`) exposing:
  - main verilog` – dump Verilog RTL
  - main vhdl`   – dump VHDL RTL
  - main simulate` – run full test-suite & generate waveform
- Comprehensive test vectors (NIST AESAVS) in
  `test/test_primitives/test_block_ciphers/test_aes`.

### Changed


### Fixed

### Security
- No known security issues.

---

## [0.0.1] – 2025-07-17

### Initial release
- Repository skeleton with AES-128 PoC.
