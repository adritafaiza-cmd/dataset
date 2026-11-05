#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BENCH="$ROOT/benchmarks/spi_master_slave"
mkdir -p "$ROOT/build/sim"
XRUN_MODE=()
if [[ "${COMPILE_ONLY:-0}" == "1" ]]; then
  XRUN_MODE=(-elaborate)
fi
xrun "${XRUN_MODE[@]}" -64bit -sv -timescale 1ns/1ps -top spi_master_slave_tb \
  -xmlibdirname "$ROOT/build/sim/spi_master_slave" \
  "$BENCH/fixed/rtl/spi_master.v" \
  "$BENCH/fixed/rtl/spi_slave.v" \
  "$BENCH/tb/spi_master_slave_tb.v"
