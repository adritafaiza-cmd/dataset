#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BENCH="$ROOT/benchmarks/axis_async_fifo_adapter"
mkdir -p "$ROOT/build/sim"
XRUN_MODE=()
if [[ "${COMPILE_ONLY:-0}" == "1" ]]; then
  XRUN_MODE=(-elaborate)
fi
xrun "${XRUN_MODE[@]}" -64bit -sv -timescale 1ns/1ps -top axis_async_fifo_adapter_smoke_tb \
  -xmlibdirname "$ROOT/build/sim/axis_async_fifo_adapter" \
  "$BENCH/fixed/rtl/axis_async_fifo_adapter.v" \
  "$BENCH/fixed/rtl/axis_async_fifo.v" \
  "$BENCH/fixed/rtl/axis_adapter.v" \
  "$BENCH/tb/axis_async_fifo_adapter_smoke_tb.v"
