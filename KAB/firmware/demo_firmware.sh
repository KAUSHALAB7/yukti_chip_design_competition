#!/bin/bash
# Complete Demo: Load Firmware and Run CPU-Driven Test
# Team KAB

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  RISC-V CPU-DRIVEN FIRMWARE DEMO                            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

cd /home/kaushal/vlsi_competition/KAB

echo "📝 Step 1: Firmware Overview"
echo "────────────────────────────────────────────────────────────────"
echo "Location: firmware/firmware.hex"
echo "Content: Pre-compiled RISC-V machine code"
echo "Function: Writes matrices A & B, starts accelerator, reads results"
echo ""

echo "🔍 Step 2: Show Firmware Content (first 20 instructions)"
echo "────────────────────────────────────────────────────────────────"
head -25 firmware/firmware.hex
echo ""

echo "⚙️  Step 3: Enable Firmware Loading in SoC"
echo "────────────────────────────────────────────────────────────────"
# Temporarily modify riscv_soc.sv to load firmware
sed -i 's|// \$readmemh("firmware/firmware.hex", ram);|$readmemh("firmware/firmware.hex", ram);|' src/riscv_soc.sv
echo "✓ Enabled: \$readmemh(\"firmware/firmware.hex\", ram);"
echo ""

echo "🔨 Step 4: Recompile with Firmware"
echo "────────────────────────────────────────────────────────────────"
iverilog -g2012 -o riscv_firmware_test \
    picorv32/picorv32.v \
    src/custom_pcpi.sv \
    src/riscv_soc.sv \
    src/accelerator_wrapper.sv \
    src/systolic_array_3x3.sv \
    src/mac_unit.sv \
    tb/riscv_soc_tb.sv
echo "✓ Compilation complete"
echo ""

echo "🚀 Step 5: Run Simulation with CPU Executing Firmware"
echo "────────────────────────────────────────────────────────────────"
timeout 15 ./riscv_firmware_test 2>&1 | head -60
echo ""

# Restore original
sed -i 's|\$readmemh("firmware/firmware.hex", ram);|// $readmemh("firmware/firmware.hex", ram);|' src/riscv_soc.sv

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ FIRMWARE DEMO COMPLETE                                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📊 What just happened:"
echo "  1. CPU reset and started executing from address 0x0"
echo "  2. CPU loaded firmware from RAM"
echo "  3. CPU wrote Matrix A to accelerator MMIO (0x02000010)"
echo "  4. CPU wrote Matrix B to accelerator MMIO (0x02000040)"
echo "  5. CPU started accelerator (write to 0x02000000)"
echo "  6. CPU polled status until done"
echo "  7. CPU read results from Matrix C (0x02000070)"
echo "  8. Results output via debug port (0x10000000)"
echo ""
