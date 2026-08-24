#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BENCH="$ROOT/benchmarks/pulse_sync"
mkdir -p "$ROOT/build/sim"
XRUN_MODE=()
if [[ "${COMPILE_ONLY:-0}" == "1" ]]; then
  XRUN_MODE=(-elaborate)
fi
xrun "${XRUN_MODE[@]}" -64bit -sv -timescale 1ns/1ps -top pulse_sync_tb \
  -xmlibdirname "$ROOT/build/sim/pulse_sync" \
  "$BENCH/fixed/rtl/pulse_sync.v" \
  "$BENCH/tb/pulse_sync_tb.v"
