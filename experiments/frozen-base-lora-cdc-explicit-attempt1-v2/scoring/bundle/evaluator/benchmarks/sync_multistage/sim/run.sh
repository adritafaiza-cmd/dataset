#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BENCH="$ROOT/benchmarks/sync_multistage"
mkdir -p "$ROOT/build/sim"
XRUN_MODE=()
if [[ "${COMPILE_ONLY:-0}" == "1" ]]; then
  XRUN_MODE=(-elaborate)
fi
xrun "${XRUN_MODE[@]}" -64bit -sv -timescale 1ns/1ps -top sync_multistage_tb \
  -xmlibdirname "$ROOT/build/sim/sync_multistage" \
  "$BENCH/fixed/rtl/sync.sv" \
  "$BENCH/tb/sync_multistage_tb.v"
