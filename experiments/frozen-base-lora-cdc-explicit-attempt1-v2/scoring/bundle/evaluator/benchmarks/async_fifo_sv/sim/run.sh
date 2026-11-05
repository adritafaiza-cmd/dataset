#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BENCH="$ROOT/benchmarks/async_fifo_sv"
mkdir -p "$ROOT/build/sim"
XRUN_MODE=()
if [[ "${COMPILE_ONLY:-0}" == "1" ]]; then
  XRUN_MODE=(-elaborate)
fi
xrun "${XRUN_MODE[@]}" -64bit -sv -timescale 1ns/1ps -top async_fifo_sv_tb \
  -xmlibdirname "$ROOT/build/sim/async_fifo_sv" \
  "$BENCH/fixed/rtl/async_fifo.sv" \
  "$BENCH/fixed/rtl/fifomem.sv" \
  "$BENCH/fixed/rtl/rptr_empty.sv" \
  "$BENCH/fixed/rtl/wptr_full.sv" \
  "$BENCH/fixed/rtl/sync_r2w.sv" \
  "$BENCH/fixed/rtl/sync_w2r.sv" \
  "$BENCH/tb/async_fifo_sv_tb.v"
