#!/usr/bin/env python3

# Let's calculate what the correct test vectors should be for our test cases
# Since I know the all-zero case should be 66e94bd4ef8a2c3b884cfa59ca342b2e

test_cases = [
    ("All zeros", "00000000000000000000000000000000", "00000000000000000000000000000000"),
    ("Pattern", "0f0e0d0c0b0a09080706050403020100", "0123456789abcdef0123456789abcdef"),
    ("Incremental", "000102030405060708090a0b0c0d0e0f", "101112131415161718191a1b1c1d1e1f"),
]

print("AES-128 ECB test vectors:")
for name, key, plaintext in test_cases:
    print(f"{name}:")
    print(f"  Key: {key}")
    print(f"  Plaintext: {plaintext}")
    # We know the first one should be 66e94bd4ef8a2c3b884cfa59ca342b2e
    if name == "All zeros":
        print(f"  Expected: 66e94bd4ef8a2c3b884cfa59ca342b2e")
    else:
        print(f"  Expected: [need to calculate]")
    print()