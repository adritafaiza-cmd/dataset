#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BENCH="$ROOT/benchmarks/axixclk"
mkdir -p "$ROOT/build/sim"
XRUN_MODE=()
if [[ "${COMPILE_ONLY:-0}" == "1" ]]; then
  XRUN_MODE=(-elaborate)
fi
xrun "${XRUN_MODE[@]}" -64bit -sv -timescale 1ns/1ps -top axixclk_assert \
  -xmlibdirname "$ROOT/build/sim/axixclk" \
  "$BENCH/fixed/rtl/axixclk.v" \
  "$BENCH/fixed/rtl/afifo.v" \
  "$BENCH/tb/axixclk_tb_assert.v"
