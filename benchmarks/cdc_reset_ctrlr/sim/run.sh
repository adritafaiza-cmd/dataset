#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BENCH="$ROOT/benchmarks/cdc_reset_ctrlr"
mkdir -p "$ROOT/build/sim"
XRUN_MODE=()
if [[ "${COMPILE_ONLY:-0}" == "1" ]]; then
  XRUN_MODE=(-elaborate)
fi
xrun "${XRUN_MODE[@]}" -64bit -sv -timescale 1ns/1ps -top cdc_reset_ctrlr_tb \
  -xmlibdirname "$ROOT/build/sim/cdc_reset_ctrlr" \
  "$BENCH/fixed/rtl/cdc_reset_ctrlr.v" \
  "$BENCH/tb/cdc_reset_ctrlr_tb.v"
