#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BENCH="$ROOT/benchmarks/apbxclk"
mkdir -p "$ROOT/build/sim"
XRUN_MODE=()
if [[ "${COMPILE_ONLY:-0}" == "1" ]]; then
  XRUN_MODE=(-elaborate)
fi
xrun "${XRUN_MODE[@]}" -64bit -sv -timescale 1ns/1ps -top apbxclk_assert \
  -xmlibdirname "$ROOT/build/sim/apbxclk" \
  "$BENCH/fixed/rtl/apbxclk.v" \
  "$BENCH/tb/apbxclk_tb_assert.v"
