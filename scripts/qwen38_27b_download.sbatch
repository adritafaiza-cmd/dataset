#!/bin/bash
#SBATCH --job-name=qwen38-27b-download
#SBATCH --account=torch_pr_1269_tandon_advanced
#SBATCH --partition=cpu_short
#SBATCH --cpus-per-task=4
#SBATCH --mem=24G
#SBATCH --time=04:00:00
#SBATCH --output=/scratch/ft2335/dataset-observable/experiments/qwen38-27b-3prompt-10attempt-v1/download-%j.log
set -euo pipefail
cd /scratch/ft2335/dataset-observable
export HF_HOME="$PWD/.cache/huggingface"
unset HF_HUB_OFFLINE TRANSFORMERS_OFFLINE
PY="$PWD/.cache/qwen38-venv/bin/python"
"$PY" -c 'from transformers import Qwen3_5ForConditionalGeneration, AutoTokenizer; import torch; print(torch.__version__)'
"$PY" -m pip freeze > experiments/qwen38-27b-3prompt-10attempt-v1/requirements-resolved.txt
"$PY" -u scripts/download_qwen38_27b.py
touch experiments/qwen38-27b-3prompt-10attempt-v1/download.complete
