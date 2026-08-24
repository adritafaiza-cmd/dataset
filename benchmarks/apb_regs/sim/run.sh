#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BENCH="$ROOT/benchmarks/apb_regs"
mkdir -p "$ROOT/build/sim"
XRUN_MODE=()
if [[ "${COMPILE_ONLY:-0}" == "1" ]]; then
  XRUN_MODE=(-elaborate)
fi
xrun "${XRUN_MODE[@]}" -64bit -sv -timescale 1ns/1ps -top apb_regs_tb \
  -incdir "$BENCH/fixed/rtl/include" \
  -incdir "$ROOT/vendor/common_cells/include" \
  -xmlibdirname "$ROOT/build/sim/apb_regs" \
  "$BENCH/fixed/rtl/cf_math_pkg.sv" \
  "$BENCH/fixed/rtl/apb_pkg.sv" \
  "$BENCH/fixed/rtl/apb_intf.sv" \
  "$BENCH/fixed/rtl/addr_decode.sv" \
  "$BENCH/fixed/rtl/apb_regs.sv" \
  "$BENCH/tb/apb_regs_tb.sv"
