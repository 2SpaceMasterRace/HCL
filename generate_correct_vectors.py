#!/usr/bin/env python3
"""Generate correct AES test vectors for all test cases."""

try:
    from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
    from cryptography.hazmat.backends import default_backend
    
    def aes_encrypt_ecb(key_hex, plaintext_hex):
        key_bytes = bytes.fromhex(key_hex)
        plaintext_bytes = bytes.fromhex(plaintext_hex)
        cipher = Cipher(algorithms.AES(key_bytes), modes.ECB(), backend=default_backend())
        encryptor = cipher.encryptor()
        ciphertext = encryptor.update(plaintext_bytes) + encryptor.finalize()
        return ciphertext.hex()
    
    def aes_decrypt_ecb(key_hex, ciphertext_hex):
        key_bytes = bytes.fromhex(key_hex)
        ciphertext_bytes = bytes.fromhex(ciphertext_hex)
        cipher = Cipher(algorithms.AES(key_bytes), modes.ECB(), backend=default_backend())
        decryptor = cipher.decryptor()
        plaintext = decryptor.update(ciphertext_bytes) + decryptor.finalize()
        return plaintext.hex()
    
    # Test cases from the implementation
    test_cases = [
        ("All zeros", "00000000000000000000000000000000", "00000000000000000000000000000000"),
        ("Pattern", "0f0e0d0c0b0a09080706050403020100", "0123456789abcdef0123456789abcdef"),
        ("Incremental", "000102030405060708090a0b0c0d0e0f", "101112131415161718191a1b1c1d1e1f"),
    ]
    
    print("=== ENCRYPTION TEST VECTORS ===")
    for name, key, plaintext in test_cases:
        ciphertext = aes_encrypt_ecb(key, plaintext)
        print(f'{name}: key={key}, pt={plaintext}, ct={ciphertext}')
    
    print("\n=== DECRYPTION TEST VECTORS ===")
    for name, key, plaintext in test_cases:
        ciphertext = aes_encrypt_ecb(key, plaintext)
        decrypted = aes_decrypt_ecb(key, ciphertext)
        print(f'{name}: key={key}, ct={ciphertext}, pt={decrypted}')
    
    # Generate OCaml code
    print("\n=== OCAML TEST CASE UPDATES ===")
    for name, key, plaintext in test_cases:
        ciphertext = aes_encrypt_ecb(key, plaintext)
        decrypted = aes_decrypt_ecb(key, ciphertext)
        print(f'  let test_enc_{name.lower().replace(" ", "_")} = test_encrypt ("{name} test",')
        print(f'                            "{key}",')
        print(f'                            "{plaintext}",')
        print(f'                            "{ciphertext}") in')
        print()
        print(f'  let test_dec_{name.lower().replace(" ", "_")} = test_decrypt ("{name} test",')
        print(f'                            "{key}",')
        print(f'                            "{ciphertext}",')
        print(f'                            "{decrypted}") in')
        print()

except ImportError:
    print("cryptography library not available, using known vectors:")
    print("All zeros: 66e94bd4ef8a2c3b884cfa59ca342b2e")
    print("Pattern: (need to calculate)")
    print("Incremental: (need to calculate)")