
# BogusEncryptionStandard (BES)

BogusEncryptionStandard (BES) is an **ironic encryption algorithm** designed for educational and entertainment purposes. It leverages the `aesenc` x86 opcode as a pseudo-random number generator (PRNG) to encrypt data in a highly inefficient and impractical manner. **Please note that BES is not intended for real-world cryptographic use and should not be used to secure sensitive information.**

## Table of Contents

- [Overview](#overview)
- [How It Works](#how-it-works)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Building the Project](#building-the-project)
- [Usage](#usage)
  - [Command-Line Options](#command-line-options)
  - [Examples](#examples)
- [Testing](#testing)
- [License](#license)

## Overview

BES encrypts data by iteratively generating outputs with the help of `aesenc` instruction until the first byte of the output matches the byte to be encrypted. The ciphertext consists of the number of iterations it took to find each matching byte. The decryption process reverses this by regenerating the PRNG outputs using the same seed and counts.

## How It Works

1. **Encryption:**
   - For each byte in the plaintext:
     - Initialize a counter to zero.
     - Generate a PRNG output using `aesenc` with the current seed.
     - Increment the counter.
     - If the first byte of the PRNG output matches the plaintext byte, record the counter value as part of the ciphertext.
     - Update the seed with the latest PRNG output.
   - The ciphertext is a sequence of counters representing the number of iterations for each byte.

*Note: if the required byte is not found after 65535 iterations, everything goes up in flames, since it is obviously the user's fault for picking a faulty key. However the probabiliy of that is like 10^-112*

2. **Decryption:**
   - For each counter in the ciphertext:
     - Use the initial seed to generate PRNG outputs.
     - Iterate the PRNG the number of times specified by the counter.
     - The first byte of the final PRNG output is the decrypted byte.
     - Update the seed with the latest PRNG output.

## Getting Started

### Prerequisites

- **Zig Programming Language** (version 0.13.0 or later)
- **NASM** assembler (for assembling the ASM code)
- **x86-64 CPU** with support for AES-NI and AVX instructions

### Building the Project

BES can be built on both **Linux** and **Windows** systems.

1. **Clone the Repository:**

   ```
   git clone https://github.com/forentfraps/BES.git
   cd BES
   ```
2. **Build it**
   ```
   zig build
   ```

## Usage

### Command-Line Options
```

-e                 Encrypt mode
-d                 Decrypt mode
-k [hex_string]    16-byte key in hex (default: 0xDEADBEEFCAFEBABEEF)
-i [filepath]      Input file path
-o [filepath]      Output file path (default: output.enc)
-h                 Display help menu
```

### Examples
 - Encrypt a file:
 ```
 ./bes -e -i plaintext.txt -o ciphertext.enc -k DEADBEEFCAFEBABEEF
 ```
 - Decrypt a file:
 ```
 ./bes -d -i ciphertext.enc -o decrypted.txt -k DEADBEEFCAFEBABEEF
 ```
 - Display a help menu:
 ```
 ./bes -h
 ```

## Testing

The project includes a test suite to verify the correctness of the encryption and decryption functions.
 - Run tests:
 ```
 zig build test
 ```

## Licence
This project is licensed under the MIT License. See the LICENSE file for details.


