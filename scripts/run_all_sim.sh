#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for run_script in "$ROOT"/benchmarks/*/sim/run.sh; do
  benchmark="$(basename "$(dirname "$(dirname "$run_script")")")"
  echo "=== Simulating $benchmark ==="
  "$run_script"
done
