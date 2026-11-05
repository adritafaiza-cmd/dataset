#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BENCH="$ROOT/benchmarks/cdc_4phase"
mkdir -p "$ROOT/build/sim"
XRUN_MODE=()
if [[ "${COMPILE_ONLY:-0}" == "1" ]]; then
  XRUN_MODE=(-elaborate)
fi
xrun "${XRUN_MODE[@]}" -64bit -sv -timescale 1ns/1ps -top cdc_4phase_tb \
  -xmlibdirname "$ROOT/build/sim/cdc_4phase" \
  "$BENCH/fixed/rtl/cdc_4phase.v" \
  "$BENCH/tb/cdc_4phase_tb.v"
