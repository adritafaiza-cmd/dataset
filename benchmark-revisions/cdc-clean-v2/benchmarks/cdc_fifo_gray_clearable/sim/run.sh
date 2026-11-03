#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BENCH="$ROOT/benchmarks/cdc_fifo_gray_clearable"
mkdir -p "$ROOT/build/sim"
XRUN_MODE=()
if [[ "${COMPILE_ONLY:-0}" == "1" ]]; then
  XRUN_MODE=(-elaborate)
fi
xrun "${XRUN_MODE[@]}" -64bit -sv -timescale 1ns/1ps -top cdc_fifo_gray_clearable_tb \
  -xmlibdirname "$ROOT/build/sim/cdc_fifo_gray_clearable" \
  "$BENCH/fixed/rtl/cdc_fifo_gray_clearable.v" \
  "$BENCH/tb/cdc_fifo_gray_clearable_tb.v"
