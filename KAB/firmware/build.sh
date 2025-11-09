#!/bin/bash
# Firmware Compilation Script for RISC-V
# Team KAB

set -e

echo "=========================================="
echo "RISC-V Firmware Build"
echo "=========================================="

# Check for RISC-V toolchain
if ! command -v riscv32-unknown-elf-gcc &> /dev/null; then
    echo "⚠️  RISC-V toolchain not found!"
    echo "Attempting to use alternative toolchain names..."
    
    # Try alternative names
    if command -v riscv64-unknown-elf-gcc &> /dev/null; then
        RISCV_PREFIX="riscv64-unknown-elf-"
        ARCH_FLAGS="-march=rv32i -mabi=ilp32"
    elif command -v riscv32-linux-gnu-gcc &> /dev/null; then
        RISCV_PREFIX="riscv32-linux-gnu-"
        ARCH_FLAGS="-march=rv32i -mabi=ilp32"
    else
        echo "❌ ERROR: No RISC-V toolchain found!"
        echo ""
        echo "Install instructions:"
        echo "  Ubuntu/Debian: sudo apt install gcc-riscv64-unknown-elf"
        echo "  Or build from: https://github.com/riscv-collab/riscv-gnu-toolchain"
        echo ""
        echo "⚙️  Generating demo firmware.hex manually..."
        generate_demo_hex
        exit 0
    fi
else
    RISCV_PREFIX="riscv32-unknown-elf-"
    ARCH_FLAGS="-march=rv32i -mabi=ilp32"
fi

echo "✓ Using toolchain: ${RISCV_PREFIX}"

# Compile assembly
echo "→ Compiling start.S..."
${RISCV_PREFIX}gcc ${ARCH_FLAGS} -c start.S -o start.o

# Link
echo "→ Linking..."
${RISCV_PREFIX}gcc ${ARCH_FLAGS} -T link.ld -nostdlib -o firmware.elf start.o

# Generate hex file
echo "→ Generating hex file..."
${RISCV_PREFIX}objcopy -O verilog firmware.elf firmware.hex

# Generate binary for inspection
${RISCV_PREFIX}objcopy -O binary firmware.elf firmware.bin

# Disassembly for debugging
echo "→ Creating disassembly..."
${RISCV_PREFIX}objdump -d firmware.elf > firmware.dis

echo ""
echo "✅ Build complete!"
echo ""
echo "Generated files:"
ls -lh firmware.elf firmware.hex firmware.bin firmware.dis

echo ""
echo "📝 To load in simulation:"
echo "   Add to riscv_soc.sv initial block:"
echo "   \$readmemh(\"firmware/firmware.hex\", ram);"

# Function to generate demo hex if no toolchain
generate_demo_hex() {
    cat > firmware.hex << 'EOF'
@00000000
00400093 // li sp, 0x4000
00C00113 // call offset
00100073 // ebreak
02000537 // lui x10, 0x2000 (main:)
01050593 // addi x11, x10, 0x10
00B50633 // add x12, x10, x11
00100693 // li x13, 1
00D62023 // sw x13, 0(x12)
00200693 // li x13, 2
00D62223 // sw x13, 4(x12)
00300693 // li x13, 3
00D62423 // sw x13, 8(x12)
EOF
    echo "✓ Demo firmware.hex created (limited functionality)"
}
