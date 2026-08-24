#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BENCH="$ROOT/benchmarks/axi_dma"
mkdir -p "$ROOT/build/sim"
XRUN_MODE=()
if [[ "${COMPILE_ONLY:-0}" == "1" ]]; then
  XRUN_MODE=(-elaborate)
fi
xrun "${XRUN_MODE[@]}" -64bit -sv -timescale 1ns/1ps -top axi_dma_tb \
  -xmlibdirname "$ROOT/build/sim/axi_dma" \
  "$BENCH/fixed/rtl/axi_dma.v" \
  "$BENCH/fixed/rtl/axi_dma_rd.v" \
  "$BENCH/fixed/rtl/axi_dma_wr.v" \
  "$BENCH/tb/axi_dma_tb.v"
