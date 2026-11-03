#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BENCH="$ROOT/benchmarks/async_bidir_ramif_fifo"
mkdir -p "$ROOT/build/sim"
XRUN_MODE=()
if [[ "${COMPILE_ONLY:-0}" == "1" ]]; then
  XRUN_MODE=(-elaborate)
fi
xrun "${XRUN_MODE[@]}" -64bit -sv -timescale 1ns/1ps -top async_bidir_ramif_fifo_tb \
  -xmlibdirname "$ROOT/build/sim/async_bidir_ramif_fifo" \
  "$BENCH/fixed/rtl/async_bidir_ramif_fifo.v" \
  "$BENCH/fixed/rtl/sync_ptr.v" \
  "$BENCH/fixed/rtl/wptr_full.v" \
  "$BENCH/fixed/rtl/rptr_empty.v" \
  "$BENCH/tb/async_bidir_ramif_fifo_tb.v"
