#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BENCH="$ROOT/benchmarks/uart16550"
mkdir -p "$ROOT/build/sim"
XRUN_MODE=()
if [[ "${COMPILE_ONLY:-0}" == "1" ]]; then
  XRUN_MODE=(-elaborate)
fi
xrun "${XRUN_MODE[@]}" -64bit -sv -timescale 1ns/1ps -top uart16550_tb \
  -define DATA_BUS_WIDTH_8 \
  -incdir "$BENCH/fixed/rtl" \
  -xmlibdirname "$ROOT/build/sim/uart16550" \
  "$BENCH/fixed/rtl/raminfr.v" \
  "$BENCH/fixed/rtl/timescale.v" \
  "$BENCH/fixed/rtl/uart_debug_if.v" \
  "$BENCH/fixed/rtl/uart_defines.v" \
  "$BENCH/fixed/rtl/uart_receiver.v" \
  "$BENCH/fixed/rtl/uart_regs.v" \
  "$BENCH/fixed/rtl/uart_rfifo.v" \
  "$BENCH/fixed/rtl/uart_sync_flops.v" \
  "$BENCH/fixed/rtl/uart_tfifo.v" \
  "$BENCH/fixed/rtl/uart_top.v" \
  "$BENCH/fixed/rtl/uart_transmitter.v" \
  "$BENCH/fixed/rtl/uart_wb.v" \
  "$BENCH/tb/uart16550_tb.v"
