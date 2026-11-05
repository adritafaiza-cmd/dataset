#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BENCH="$ROOT/benchmarks/sync_reset"
mkdir -p "$ROOT/build/sim"
XRUN_MODE=()
if [[ "${COMPILE_ONLY:-0}" == "1" ]]; then
  XRUN_MODE=(-elaborate)
fi
xrun "${XRUN_MODE[@]}" -64bit -sv -timescale 1ns/1ps -top sync_reset_tb \
  -xmlibdirname "$ROOT/build/sim/sync_reset" \
  "$BENCH/fixed/rtl/sync_reset.v" \
  "$BENCH/tb/sync_reset_tb.v"
