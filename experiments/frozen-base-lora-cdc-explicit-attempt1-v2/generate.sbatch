#!/bin/bash
#SBATCH --job-name=frozen-v2
#SBATCH --account=torch_pr_1269_tandon_advanced
#SBATCH --partition=h200_tandon
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --gres=gpu:h200:1
#SBATCH --mem=96G
#SBATCH --time=06:00:00
#SBATCH --array=0-15%16
#SBATCH --output=/scratch/ft2335/dataset-observable/experiments/frozen-base-lora-cdc-explicit-attempt1-v2/generate-%A-%a.log
set -euo pipefail
cd /scratch/ft2335/dataset-observable
export HF_HUB_OFFLINE=1 TRANSFORMERS_OFFLINE=1 TOKENIZERS_PARALLELISM=false OMP_NUM_THREADS=4
export HF_HOME="$PWD/.cache/huggingface"
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
experiment="$PWD/experiments/frozen-base-lora-cdc-explicit-attempt1-v2"
rank=$((SLURM_ARRAY_TASK_ID % 8))
arm=base
extra=()
if (( SLURM_ARRAY_TASK_ID >= 8 )); then
    arm=lora
    extra=(--adapter "$experiment/adapter")
fi
set +e
.cache/qwen38-venv/bin/python -u "$experiment/generate.py" --repo "$experiment/inputs" --output "$experiment/$arm" --prompt-types cdc_explicit --attempts 1 --world-size 8 --rank "$rank" "${extra[@]}"
result=$?
printf '%s\n' "$result" > "$experiment/exit-$arm-$rank.txt"
exit "$result"
