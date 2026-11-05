#!/bin/bash
set -u
cd /home/ft2335/dataset
LOG=logs/score-openrouter-3prompt.log
echo "START $(date -Is)" | tee -a "$LOG"

python3 -u scripts/evaluate_icarus_observable.py \
  --experiment-root experiments/multi-llm-3prompt-v1/openrouter \
  >> "$LOG" 2>&1
echo "ICARUS_EXIT=$? $(date -Is)" | tee -a "$LOG"

python3 -u scripts/evaluate_symbiyosys_eligible.py \
  --openrouter-root experiments/multi-llm-3prompt-v1/openrouter \
  --summary formal/openrouter_3prompt_summary.json \
  --resume \
  >> "$LOG" 2>&1
echo "FORMAL_EXIT=$? $(date -Is)" | tee -a "$LOG"

python3 -u scripts/run_enhanced_cdc_openrouter_3prompt.py --resume \
  >> "$LOG" 2>&1
echo "ENHANCED_EXIT=$? $(date -Is)" | tee -a "$LOG"
echo "ALL_DONE $(date -Is)" | tee -a "$LOG"
