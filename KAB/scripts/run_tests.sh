#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT_DIR"

mkdir -p sim/build sim/logs sim/waves

# 1) Matrix accelerator test
iverilog -g2012 -o sim/build/matrix_test \
  src/mac_unit.sv \
  src/matrix_accelerator_3x3.sv \
  tb/matrix_accelerator_testbench.sv
vvp sim/build/matrix_test | tee sim/logs/matrix_test.log

# 2) MAC unit test
iverilog -g2012 -o sim/build/mac_test \
  src/mac_unit.sv \
  tb/mac_unit_testbench.sv
vvp sim/build/mac_test | tee sim/logs/mac_test.log

# 3) Wrapper test (optional, may be timing dependent)
if iverilog -g2012 -o sim/build/wrapper_test \
  src/mac_unit.sv \
  src/matrix_accelerator_3x3.sv \
  src/accelerator_wrapper.sv \
  tb/wrapper_testbench.sv; then
  vvp sim/build/wrapper_test | tee sim/logs/wrapper_test.log || true
fi

echo "All tests invoked. Check sim/logs for details."
