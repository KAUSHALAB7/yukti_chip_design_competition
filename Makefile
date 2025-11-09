# Simple simulation Makefile for local iteration

TOP      ?= top_tb
# Use KAB as the active RTL team directory
RTL_DIR  ?= KAB/src
TB_DIR   ?= KAB/tb
BUILD    ?= KAB/sim/build
LOGS     ?= KAB/sim/logs
WAVES    ?= KAB/sim/waves

RTL_SRCS := $(wildcard $(RTL_DIR)/*.v) $(wildcard $(RTL_DIR)/*.sv)
TB_SRCS  := $(wildcard $(TB_DIR)/*.v) $(wildcard $(TB_DIR)/*.sv)

.PHONY: all lint sim-iverilog sim-verilator wave clean dirs

all: sim-iverilog

dirs:
	@mkdir -p $(BUILD) $(LOGS) $(WAVES)

lint: | dirs
	@echo "[lint] Verilator lint (skips if not installed)"
	@command -v verilator >/dev/null 2>&1 \
		&& verilator --lint-only -Wall $(RTL_SRCS) $(TB_SRCS) > $(LOGS)/verilator.lint 2>&1 \
		|| echo "verilator not found, skipping lint"

sim-iverilog: | dirs
	@echo "[sim] Icarus Verilog compile+run"
	@iverilog -g2012 -o $(BUILD)/simv $(RTL_SRCS) $(TB_SRCS)
	@vvp $(BUILD)/simv | tee $(LOGS)/sim_iverilog.log

# Note: This uses --binary so no C++ harness is needed; may require recent Verilator.
sim-verilator: | dirs
	@echo "[sim] Verilator binary build+run (skips if not installed)"
	@command -v verilator >/dev/null 2>&1 \
		&& (verilator -Wall --binary -j 0 --top-module $(TOP) $(TB_SRCS) $(RTL_SRCS) -o $(BUILD)/V$(TOP) \
		&& $(BUILD)/V$(TOP) | tee $(LOGS)/sim_verilator.log) \
		|| echo "verilator not found, skipping verilator sim"

wave:
	@command -v gtkwave >/dev/null 2>&1 \
		&& gtkwave $(WAVES)/*.vcd & \
		|| echo "gtkwave not found, skipping waveform viewer"

clean:
	@rm -rf $(BUILD) obj_dir $(LOGS) $(WAVES)
	@mkdir -p $(BUILD) $(LOGS) $(WAVES)
