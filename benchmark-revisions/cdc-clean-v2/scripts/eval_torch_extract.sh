#!/usr/bin/env bash
# Evaluate the Torch-extracted tree at dataset/torch.
# Run this on ecs05 in your own terminal so Xcelium/Jasper can get licenses.
set -u
TORCH="${TORCH:-/home/ft2335/dataset/torch}"
export DS="$TORCH"
LOG="${LOG:-/home/ft2335/dataset/build/sim/torch_eval.log}"
mkdir -p /home/ft2335/dataset/build/sim "$TORCH/build/sim" "$TORCH/build/jasper"
exec > >(tee -a "$LOG") 2>&1

echo "===== $(date) Torch extract: $TORCH ====="
echo "hostname=$(hostname)"

PILOTS=(cdc_2phase async_fifo apbxclk)
echo
echo "===== Functional sim (xrun) ====="
for c in "${PILOTS[@]}"; do
  echo "=== SIM $c ==="
  if "$TORCH/benchmarks/$c/sim/run.sh"; then
    echo "RESULT $c SIM: PASS"
  else
    echo "RESULT $c SIM: FAIL exit $?"
  fi
done

echo
echo "===== JasperGold CDC ====="
for c in "${PILOTS[@]}"; do
  echo "=== JG $c ==="
  work="$TORCH/build/jasper/work_$c"
  mkdir -p "$work"
  if (cd "$work" && jg -batch "$TORCH/benchmarks/$c/jasper/run.tcl"); then
    echo "RESULT $c JG: PASS (tool exit 0)"
  else
    echo "RESULT $c JG: FAIL exit $?"
  fi
  if [[ -f "$TORCH/build/jasper/$c/cdc_report.rpt" ]]; then
    echo "--- $c cdc_report.rpt ---"
    cat "$TORCH/build/jasper/$c/cdc_report.rpt"
  fi
done

echo "===== done $(date) ====="
echo "Log: $LOG"
