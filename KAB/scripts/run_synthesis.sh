#!/bin/bash
# Team KAB - Automated Synthesis Setup Script
# Run this on the server after transferring files

echo "========================================"
echo "Team KAB - Matrix Multiplier Synthesis"
echo "========================================"

# 1. Setup environment
echo ""
echo "[1/5] Setting up tools..."
source /nfsTOOLS/synopsys_tools
echo "   ✓ VCS: $(which vcs)"
echo "   ✓ DC:  $(which dc_shell)"

# 2. Create directory structure
echo ""
echo "[2/5] Creating directories..."
mkdir -p ~/kab_synth/{rtl,tb,sim,synth,reports,logs}
cd ~/kab_synth
echo "   ✓ Working directory: $(pwd)"

# 3. Check files
echo ""
echo "[3/5] Checking RTL files..."
if [ -f rtl/mac_unit.sv ] && [ -f rtl/systolic_array_3x3.sv ]; then
    echo "   ✓ mac_unit.sv found"
    echo "   ✓ systolic_array_3x3.sv found"
else
    echo "   ✗ ERROR: RTL files missing!"
    echo "   Please copy files with:"
    echo "   scp src/*.sv guest18@192.168.30.91:~/kab_synth/rtl/"
    exit 1
fi

# 4. VCS Simulation
echo ""
echo "[4/5] Running VCS simulation..."
cd sim
vcs -sverilog -full64 -o matrix_sim \
    ../rtl/mac_unit.sv \
    ../rtl/systolic_array_3x3.sv \
    ../tb/systolic_array_tb.sv \
    2>&1 | tee ../logs/vcs_compile.log

if [ -f matrix_sim ]; then
    echo "   ✓ VCS compilation successful"
    ./matrix_sim | tee ../logs/vcs_sim.log
    if grep -q "PASSED" ../logs/vcs_sim.log; then
        echo "   ✓ Simulation PASSED"
    else
        echo "   ⚠ Check simulation results"
    fi
else
    echo "   ✗ VCS compilation failed"
    exit 1
fi

# 5. Design Compiler Synthesis
echo ""
echo "[5/5] Running Design Compiler synthesis..."
echo "   → This will be done interactively"
echo "   → Ask instructor for PDK library path first!"
echo ""
echo "Next steps:"
echo "1. Get PDK path from instructor"
echo "2. Run: dc_shell -f synth/synth_script.tcl"
echo ""
echo "✓ Setup complete!"
