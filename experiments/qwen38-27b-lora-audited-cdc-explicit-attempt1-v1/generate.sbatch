#!/bin/bash
#SBATCH --job-name=cdc-lora-compare
#SBATCH --account=torch_pr_1269_tandon_advanced
#SBATCH --partition=h200_tandon
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --gres=gpu:h200:1
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --output=/scratch/ft2335/dataset-observable/experiments/qwen38-27b-lora-audited-cdc-explicit-attempt1-v1/generate-%j.log
set -euo pipefail
cd /scratch/ft2335/dataset-observable
export HF_HUB_OFFLINE=1 TRANSFORMERS_OFFLINE=1 TOKENIZERS_PARALLELISM=false OMP_NUM_THREADS=4
export HF_HOME="$PWD/.cache/huggingface"
exec .cache/qwen38-venv/bin/python -u scripts/generate_qwen38_27b_3prompt.py --output experiments/qwen38-27b-lora-audited-cdc-explicit-attempt1-v1 --attempts 1 --prompt-types cdc_explicit --adapter training/cdc-lora-v1/retrain-audited/adapter "$@"
