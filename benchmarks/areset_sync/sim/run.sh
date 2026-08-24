#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BENCH="$ROOT/benchmarks/areset_sync"
mkdir -p "$ROOT/build/sim"
XRUN_MODE=()
if [[ "${COMPILE_ONLY:-0}" == "1" ]]; then
  XRUN_MODE=(-elaborate)
fi
xrun "${XRUN_MODE[@]}" -64bit -sv -timescale 1ns/1ps -top areset_sync_tb \
  -xmlibdirname "$ROOT/build/sim/areset_sync" \
  "$BENCH/fixed/rtl/areset_sync.v" \
  "$BENCH/tb/areset_sync_tb.v"
