#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BENCH="$ROOT/benchmarks/i2c_master"
mkdir -p "$ROOT/build/sim"
XRUN_MODE=()
if [[ "${COMPILE_ONLY:-0}" == "1" ]]; then
  XRUN_MODE=(-elaborate)
fi
xrun "${XRUN_MODE[@]}" -64bit -sv -timescale 1ns/1ps -top i2c_master_tb \
  -xmlibdirname "$ROOT/build/sim/i2c_master" \
  "$BENCH/fixed/rtl/i2c_master.v" \
  "$BENCH/fixed/rtl/i2c_slave.v" \
  "$BENCH/tb/i2c_master_tb.v"
