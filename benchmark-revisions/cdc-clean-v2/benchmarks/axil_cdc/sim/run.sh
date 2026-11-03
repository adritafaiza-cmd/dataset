#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BENCH="$ROOT/benchmarks/axil_cdc"
mkdir -p "$ROOT/build/sim"
XRUN_MODE=()
if [[ "${COMPILE_ONLY:-0}" == "1" ]]; then
  XRUN_MODE=(-elaborate)
fi
xrun "${XRUN_MODE[@]}" -64bit -sv -timescale 1ns/1ps -top axil_cdc_tb \
  -xmlibdirname "$ROOT/build/sim/axil_cdc" \
  "$BENCH/fixed/rtl/axil_cdc.v" \
  "$BENCH/fixed/rtl/axil_cdc_wr.v" \
  "$BENCH/fixed/rtl/axil_cdc_rd.v" \
  "$BENCH/tb/axil_cdc_tb.v"
