#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BENCH="$ROOT/benchmarks/isochronous_spill_register"
mkdir -p "$ROOT/build/sim"
XRUN_MODE=()
if [[ "${COMPILE_ONLY:-0}" == "1" ]]; then
  XRUN_MODE=(-elaborate)
fi
xrun "${XRUN_MODE[@]}" -64bit -sv -timescale 1ns/1ps -top isochronous_spill_register_tb \
  -xmlibdirname "$ROOT/build/sim/isochronous_spill_register" \
  "$BENCH/fixed/rtl/isochronous_spill_register.v" \
  "$BENCH/tb/isochronous_spill_register_tb.v"
