#!/bin/bash
#SBATCH --job-name=qwen35-download
#SBATCH --account=torch_pr_1269_tandon_advanced
#SBATCH --partition=cpu_short
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=04:00:00
#SBATCH --requeue
#SBATCH --output=/scratch/ft2335/dataset-observable/experiments/qwen35-3prompt-10attempt-v1/download-%j.log
set -euo pipefail
cd /scratch/ft2335/dataset-observable
export HF_HOME="$PWD/.cache/huggingface" PIP_CACHE_DIR="$PWD/.cache/pip"
unset HF_HUB_OFFLINE TRANSFORMERS_OFFLINE
PY="$PWD/.cache/qwen35-venv/bin/python"
"$PY" -m pip install 'transformers==5.6.0'
"$PY" -c 'from transformers import Qwen3_5ForConditionalGeneration, AutoTokenizer; import torch; print(torch.__version__)'
for attempt in 1 2 3 4 5; do
  if timeout 40m "$PY" -u scripts/download_qwen35.py --output models/Qwen3.5-9B; then
    touch experiments/qwen35-3prompt-10attempt-v1/download.complete
    exit 0
  fi
  sleep 30
done
exit 1
