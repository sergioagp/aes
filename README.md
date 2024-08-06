# AES-AXI-Burst

AES-AXI-Burst
=============

This repository contains an extension of the Secworks AES submodule to function as an AXI IP core. Additionally, it has been extended to fully encrypt and decrypt bursts of memory. The module reads a full array from one BRAM (RMEM), processes it sequentially on the AES IP, and then writes the result to another BRAM (WREM). The length of the data to be encrypted or decrypted is specified by `ADDR_BLOCK1`. The `ADDR_BLOCK2` and `ADDR_BLOCK3` registers provide insight into how many bytes were read and written, respectively. Other than these extensions, the module functions as the original AES implementation provided by Secworks.

## To-do

- [ ] Add support for ECB and other AES computation modes.

## Status

The core is completed, tested, and integrated into several FPGA designs. It is mature and reliable for use in encryption and decryption tasks involving memory bursts.

## Introduction

This implementation supports 128-bit and 256-bit keys. It processes one 128-bit block at a time in an iterative manner. The core operates on a word level with 4 S-boxes in the data path, which are shared between encryption and key expansion.

## Features

- **128-bit and 256-bit key support**: The core supports both key sizes.
- **Iterative processing**: Processes one 128-bit block at a time.
- **Burst mode**: Encrypts or decrypts bursts of memory read from RMEM and writes to WREM.
- **AXI Interface**: Extended to function as an AXI IP core.
- **Status Registers**: Provides information on the number of bytes read and written.

## Branches



## Core Usage

### Usage Sequence

1. Load the key by writing to the key register words.
2. Set the key length by writing to the config register.
3. Initialize key expansion by setting the init bit in the control register.
4. Wait for the ready bit in the status register to toggle.
5. Write the cleartext block to the block registers.
6. Start block processing by setting the next bit in the control register.
7. Wait for the ready bit in the status register to toggle.
8. Read the ciphertext block from the result registers.
9. For burst operations, provide the burst length in `ADDR_BLOCK1`, and monitor `ADDR_BLOCK2` and `ADDR_BLOCK3` for read and write byte counts.

## Implementation Results

### ASIC Implementation
 TBD
### FPGA Implementation
 
#### Xilinx ZCU104

- 2576 slices
- 3000 Registers
- 100 MHz
- 46 cycles/block

## Conclusion
This repository extends the Secworks AES core to support AXI interfaces and burst mode operations, enhancing its applicability in modern FPGA-based systems. With comprehensive usage instructions and implementation results, it provides a robust solution for AES encryption and decryption in memory-intensive applications.