#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BENCH="$ROOT/benchmarks/isochronous_4phase_handshake"
mkdir -p "$ROOT/build/sim"
XRUN_MODE=()
if [[ "${COMPILE_ONLY:-0}" == "1" ]]; then
  XRUN_MODE=(-elaborate)
fi
xrun "${XRUN_MODE[@]}" -64bit -sv -timescale 1ns/1ps -top isochronous_4phase_handshake_tb \
  -xmlibdirname "$ROOT/build/sim/isochronous_4phase_handshake" \
  "$BENCH/fixed/rtl/isochronous_4phase_handshake.v" \
  "$BENCH/tb/isochronous_4phase_handshake_tb.v"
