#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BENCH="$ROOT/benchmarks/async_fifo"
mkdir -p "$ROOT/build/sim"
XRUN_MODE=()
if [[ "${COMPILE_ONLY:-0}" == "1" ]]; then
  XRUN_MODE=(-elaborate)
fi
xrun "${XRUN_MODE[@]}" -64bit -sv -timescale 1ns/1ps -top async_fifo_unit_test \
  -xmlibdirname "$ROOT/build/sim/async_fifo" \
  "$BENCH/fixed/rtl/async_fifo.v" \
  "$BENCH/fixed/rtl/sync_r2w.v" \
  "$BENCH/fixed/rtl/sync_w2r.v" \
  "$BENCH/fixed/rtl/wptr_full.v" \
  "$BENCH/fixed/rtl/rptr_empty.v" \
  "$BENCH/fixed/rtl/fifomem.v" \
  "$BENCH/tb/async_fifo_unit_test.v"
