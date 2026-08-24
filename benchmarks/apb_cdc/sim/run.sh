#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BENCH="$ROOT/benchmarks/apb_cdc"
mkdir -p "$ROOT/build/sim"
XRUN_MODE=()
if [[ "${COMPILE_ONLY:-0}" == "1" ]]; then
  XRUN_MODE=(-elaborate)
fi
xrun "${XRUN_MODE[@]}" -64bit -sv -timescale 1ns/1ps -top apb_cdc_tb \
  -xmlibdirname "$ROOT/build/sim/apb_cdc" \
  "$BENCH/fixed/rtl/apb_cdc.v" \
  "$BENCH/fixed/rtl/cdc_fifo_gray.v" \
  "$BENCH/tb/apb_cdc_tb.v"
