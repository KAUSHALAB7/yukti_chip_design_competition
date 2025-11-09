# Design Compiler Synthesis Script
# Team KAB - 3x3 Matrix Multiplier Accelerator

# ==================================================
# STEP 1: Setup and Library Configuration
# ==================================================

# Set design name
set DESIGN "systolic_array_3x3"

# IMPORTANT: Update this path with actual PDK location from instructor!
# set PDK_PATH "/path/to/gf180mcu"
# set_app_var target_library "$PDK_PATH/libs/gf180mcu_fd_sc_mcu7t5v0__tt_025C_1v80.db"
# set_app_var link_library "* $target_library"

# For now, use generic library (DEMO ONLY - replace with actual PDK!)
set_app_var target_library "your_cell.db"
set_app_var link_library "* your_cell.db"

# ==================================================
# STEP 2: Read Design
# ==================================================

# Read RTL files
read_verilog -sv {
    ../rtl/mac_unit.sv
    ../rtl/systolic_array_3x3.sv
}

# Set current design
current_design $DESIGN

# Link design
link

# ==================================================
# STEP 3: Define Constraints
# ==================================================

# Create clock (100 MHz = 10ns period)
create_clock -name clk -period 10 [get_ports clk]

# Set clock uncertainty (jitter + skew)
set_clock_uncertainty 0.5 [get_clocks clk]

# Set clock transition
set_clock_transition 0.1 [get_clocks clk]

# Input delays (assume 20% of clock period)
set_input_delay -clock clk 2.0 [remove_from_collection [all_inputs] [get_ports clk]]

# Output delays
set_output_delay -clock clk 2.0 [all_outputs]

# Set load on outputs (assume 4 standard loads)
set_load 0.1 [all_outputs]

# Set drive strength on inputs
set_driving_cell -lib_cell BUFX2 -pin Y [remove_from_collection [all_inputs] [get_ports clk]]

# Area constraint (optimize for area)
set_max_area 0

# ==================================================
# STEP 4: Compile
# ==================================================

# First pass: High effort compile
compile_ultra -gate_clock

# ==================================================
# STEP 5: Generate Reports
# ==================================================

# Create reports directory if doesn't exist
sh mkdir -p ../reports

# Area report
report_area -hierarchy > ../reports/area_report.txt

# Timing report
report_timing -max_paths 10 -transition_time -nets -attributes > ../reports/timing_report.txt

# Power report
report_power -hierarchy > ../reports/power_report.txt

# QoR (Quality of Results) summary
report_qor > ../reports/qor_report.txt

# Constraint violations
report_constraint -all_violators > ../reports/constraints.txt

# ==================================================
# STEP 6: Write Outputs
# ==================================================

# Write synthesized netlist
write -format verilog -hierarchy -output ../synth/${DESIGN}_netlist.v

# Write SDC constraints
write_sdc ../synth/${DESIGN}.sdc

# Write DDC (Synopsys internal format)
write -format ddc -hierarchy -output ../synth/${DESIGN}.ddc

# ==================================================
# STEP 7: Summary
# ==================================================

echo "========================================"
echo "Synthesis Complete!"
echo "========================================"
echo ""
echo "Reports generated in: ../reports/"
echo "  - area_report.txt"
echo "  - timing_report.txt"
echo "  - power_report.txt"
echo "  - qor_report.txt"
echo ""
echo "Netlist: ../synth/${DESIGN}_netlist.v"
echo "========================================"

# Print quick summary to terminal
report_area
report_timing -max_paths 1
report_power

# Exit
quit
