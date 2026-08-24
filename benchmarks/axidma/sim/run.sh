#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BENCH="$ROOT/benchmarks/axidma"
mkdir -p "$ROOT/build/sim"
XRUN_MODE=()
if [[ "${COMPILE_ONLY:-0}" == "1" ]]; then
  XRUN_MODE=(-elaborate)
fi
xrun "${XRUN_MODE[@]}" -64bit -sv -timescale 1ns/1ps -top axidma_tb \
  -xmlibdirname "$ROOT/build/sim/axidma" \
  "$BENCH/fixed/rtl/axidma.v" \
  "$BENCH/fixed/rtl/skidbuffer.v" \
  "$BENCH/fixed/rtl/sfifo.v" \
  "$BENCH/tb/axidma_tb.v"
