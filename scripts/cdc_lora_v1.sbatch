#!/bin/bash
#SBATCH --job-name=cdc-lora-v1
#SBATCH --account=torch_pr_1269_tandon_advanced
#SBATCH --partition=h200_tandon
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --gres=gpu:h200:1
#SBATCH --mem=128G
#SBATCH --time=08:00:00
#SBATCH --output=/scratch/ft2335/dataset-observable/training/cdc-lora-v1/train-%j.log
set -euo pipefail
cd /scratch/ft2335/dataset-observable
export HF_HUB_OFFLINE=1 TRANSFORMERS_OFFLINE=1 TOKENIZERS_PARALLELISM=false OMP_NUM_THREADS=8
export HF_HOME="$PWD/.cache/huggingface"
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
exec .cache/qwen38-venv/bin/python -u scripts/train_cdc_lora.py
