#!/bin/bash
# Compile RISC-V firmware for matrix accelerator
# Requires riscv32-unknown-elf-gcc toolchain

set -e

TOOLCHAIN_PREFIX=riscv32-unknown-elf
GCC=${TOOLCHAIN_PREFIX}-gcc
OBJCOPY=${TOOLCHAIN_PREFIX}-objcopy
OBJDUMP=${TOOLCHAIN_PREFIX}-objdump

# Compiler flags
CFLAGS="-march=rv32imc -mabi=ilp32 -O2 -g -Wall"
CFLAGS="$CFLAGS -ffreestanding -nostdlib -nostartfiles"
CFLAGS="$CFLAGS -Wl,-Bstatic,-T,firmware/linker.ld,-Map,firmware/firmware.map,--strip-debug"

echo "🔨 Compiling RISC-V firmware..."

# Check if toolchain is available
if ! command -v ${GCC} &> /dev/null; then
    echo "❌ ERROR: ${GCC} not found!"
    echo "   Please install RISC-V toolchain:"
    echo "   Ubuntu: sudo apt install gcc-riscv64-unknown-elf"
    echo "   Or download from: https://github.com/riscv-collab/riscv-gnu-toolchain"
    exit 1
fi

# Create output directory
mkdir -p firmware/build

# Compile C code + startup
${GCC} ${CFLAGS} \
    -o firmware/build/firmware.elf \
    firmware/start.S \
    firmware/matrix_test.c

echo "✅ Compiled firmware.elf"

# Create binary
${OBJCOPY} -O binary firmware/build/firmware.elf firmware/build/firmware.bin
echo "✅ Created firmware.bin"

# Create hex file for Verilog $readmemh
${OBJCOPY} -O verilog firmware/build/firmware.elf firmware/build/firmware.hex
echo "✅ Created firmware.hex"

# Create disassembly for debugging
${OBJDUMP} -D firmware/build/firmware.elf > firmware/build/firmware.dis
echo "✅ Created firmware.dis"

# Show size
${TOOLCHAIN_PREFIX}-size firmware/build/firmware.elf

echo ""
echo "📦 Firmware build complete!"
echo "   ELF:  firmware/build/firmware.elf"
echo "   BIN:  firmware/build/firmware.bin"
echo "   HEX:  firmware/build/firmware.hex"
echo "   DIS:  firmware/build/firmware.dis"
