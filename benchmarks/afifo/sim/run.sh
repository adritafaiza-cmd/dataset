#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BENCH="$ROOT/benchmarks/afifo"
mkdir -p "$ROOT/build/sim"
XRUN_MODE=()
if [[ "${COMPILE_ONLY:-0}" == "1" ]]; then
  XRUN_MODE=(-elaborate)
fi
DUT="$BENCH/fixed/rtl/afifo.v"
CHECKS="$ROOT/cdc_tb_checks"
if [[ "${CDC_CHECKS:-1}" != "0" ]]; then
  python3 "$CHECKS/lint_cdc.py" --circuit afifo "$DUT"
fi
xrun "${XRUN_MODE[@]}" -64bit -sv -timescale 1ns/1ps -top afifo_tb \
  -xmlibdirname "$ROOT/build/sim/afifo" \
  "$DUT" \
  "$BENCH/tb/afifo_tb.v"
