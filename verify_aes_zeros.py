#!/usr/bin/env python3
"""
Verification script to check if the all-zero AES test case produces correct results.
This script will encrypt all zeros with all zeros key using a standard AES implementation
and compare with the expected result from the hardware implementation.
"""

from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend
import binascii

def aes_encrypt_ecb(key_bytes, plaintext_bytes):
    """Encrypt using AES-128 ECB mode."""
    cipher = Cipher(algorithms.AES(key_bytes), modes.ECB(), backend=default_backend())
    encryptor = cipher.encryptor()
    ciphertext = encryptor.update(plaintext_bytes) + encryptor.finalize()
    return ciphertext

def main():
    print("=== AES All-Zero Test Verification ===")
    print()
    
    # Test case from the hardware implementation
    key_hex = "00000000000000000000000000000000"
    plaintext_hex = "00000000000000000000000000000000"
    expected_hex = "dfcd9c1bd11a6beebcfb96bd93235ea9"
    
    print(f"Key:       {key_hex}")
    print(f"Plaintext: {plaintext_hex}")
    print(f"Expected:  {expected_hex}")
    print()
    
    # Convert hex strings to bytes
    key_bytes = bytes.fromhex(key_hex)
    plaintext_bytes = bytes.fromhex(plaintext_hex)
    expected_bytes = bytes.fromhex(expected_hex)
    
    # Encrypt using standard AES implementation
    result_bytes = aes_encrypt_ecb(key_bytes, plaintext_bytes)
    result_hex = result_bytes.hex()
    
    print(f"Standard AES result: {result_hex}")
    print(f"Hardware result:     {expected_hex}")
    print()
    
    # Compare results
    if result_hex.lower() == expected_hex.lower():
        print("✓ PASS: Hardware implementation matches standard AES")
        return True
    else:
        print("✗ FAIL: Hardware implementation does NOT match standard AES")
        print(f"Difference: Expected {expected_hex}, got {result_hex}")
        return False

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)