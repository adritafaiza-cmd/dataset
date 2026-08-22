#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BENCH="$ROOT/benchmarks/cdc_2phase_clearable"
mkdir -p "$ROOT/build/sim"
XRUN_MODE=()
if [[ "${COMPILE_ONLY:-0}" == "1" ]]; then
  XRUN_MODE=(-elaborate)
fi
xrun "${XRUN_MODE[@]}" -64bit -sv -timescale 1ns/1ps -incdir "$ROOT/vendor/common_cells/include" \
  -top cdc_2phase_clearable_tb \
  -xmlibdirname "$ROOT/build/sim/cdc_2phase_clearable" \
  "$ROOT/vendor/common_cells/src/cdc_reset_ctrlr_pkg.sv" \
  "$ROOT/vendor/common_cells/src/sync.sv" \
  "$ROOT/vendor/common_cells/src/spill_register.sv" \
  "$ROOT/vendor/common_cells/src/cdc_4phase.sv" \
  "$ROOT/vendor/common_cells/src/cdc_reset_ctrlr.sv" \
  "$BENCH/fixed/rtl/cdc_2phase_clearable.v" \
  "$BENCH/tb/cdc_2phase_clearable_tb.v"
