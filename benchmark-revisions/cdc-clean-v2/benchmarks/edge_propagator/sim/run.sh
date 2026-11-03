#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BENCH="$ROOT/benchmarks/edge_propagator"
mkdir -p "$ROOT/build/sim"
XRUN_MODE=()
if [[ "${COMPILE_ONLY:-0}" == "1" ]]; then
  XRUN_MODE=(-elaborate)
fi
xrun "${XRUN_MODE[@]}" -64bit -sv -timescale 1ns/1ps -top edge_propagator_tb \
  -xmlibdirname "$ROOT/build/sim/edge_propagator" \
  "$BENCH/fixed/rtl/edge_propagator.sv" \
  "$BENCH/fixed/rtl/edge_propagator_ack.sv" \
  "$BENCH/fixed/rtl/pulp_sync_wedge.sv" \
  "$BENCH/fixed/rtl/pulp_sync.sv" \
  "$BENCH/tb/edge_propagator_tb.v" \
  "$BENCH/tb/pulp_clock_gating.sv"
