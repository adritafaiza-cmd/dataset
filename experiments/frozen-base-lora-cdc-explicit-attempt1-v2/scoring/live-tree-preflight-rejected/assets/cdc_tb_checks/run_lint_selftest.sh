#!/usr/bin/env bash
# Golden must exit 0. Human-repaired and GPT attempt-001 must exit 1.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LINT="$ROOT/cdc_tb_checks/lint_cdc.py"
fail=0

ok() { python3 "$LINT" "$@" >/dev/null && echo "SELFTEST PASS: golden is clean (no CDC lint hit): $*" || { echo "SELFTEST FAIL: golden should be clean: $*"; fail=1; }; }
bad() { python3 "$LINT" "$@" >/dev/null && { echo "SELFTEST FAIL: should have caught CDC: $*"; fail=1; } || echo "SELFTEST PASS: lint caught CDC in: $*"; }

ok "$ROOT/benchmarks/cdc_2phase/fixed/rtl/cdc_2phase.v"
ok "$ROOT/benchmarks/async_fifo/fixed/rtl/async_fifo.v"
ok "$ROOT/benchmarks/apbxclk/fixed/rtl/apbxclk.v"
ok "$ROOT/benchmarks/afifo/fixed/rtl/afifo.v"
bad "$ROOT/experiments/human_repaired/cdc_2phase/generated/cdc_2phase.v"
bad "$ROOT/experiments/human_repaired/async_fifo/generated/async_fifo.v"
bad "$ROOT/experiments/human_repaired/apbxclk/generated/apbxclk.v"
bad "$ROOT/experiments/multi-llm-passk/openai/gpt-5.6-sol/cdc_2phase/functional/attempt-001/generated/cdc_2phase.v"
exit "$fail"
