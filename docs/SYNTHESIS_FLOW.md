# Synthesis Flow

These are the typical steps we follow on a Synopsys-based server.

## Prerequisites
- Synopsys Design Compiler available in PATH
- RTL in `KAB/src`, constraints in scripts/tcl if needed

## Steps

```bash
# 1) Login to server
ssh guest18@192.168.30.91

# 2) Navigate to project
cd ~/yukti_chip_design_competition  # or your chosen path

# 3) Run synthesis wrapper
./KAB/scripts/run_synthesis.sh
```

The script will:
- Read RTL from `KAB/src`
- Apply clock/area constraints (edit `KAB/scripts/synth_script.tcl`)
- Generate reports (area, timing, power) into `reports/`
- Emit a gate-level netlist

## Notes
- Adjust the top module and constraints to match your environment.
- For ICC2/PnR, feed the generated netlist and SDC accordingly.
