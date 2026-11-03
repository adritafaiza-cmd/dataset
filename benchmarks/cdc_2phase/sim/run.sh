#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BENCH="$ROOT/benchmarks/cdc_2phase"
mkdir -p "$ROOT/build/sim"
XRUN_MODE=()
if [[ "${COMPILE_ONLY:-0}" == "1" ]]; then
  XRUN_MODE=(-elaborate)
fi
DUT="$BENCH/fixed/rtl/cdc_2phase.v"
CHECKS="$ROOT/cdc_tb_checks"
if [[ "${CDC_CHECKS:-1}" != "0" ]]; then
  python3 "$CHECKS/lint_cdc.py" --circuit cdc_2phase "$DUT"
fi
xrun "${XRUN_MODE[@]}" -64bit -sv -timescale 1ns/1ps -top cdc_2phase_tb \
  -xmlibdirname "$ROOT/build/sim/cdc_2phase" \
  "$DUT" \
  "$BENCH/tb/cdc_2phase_tb.v"
