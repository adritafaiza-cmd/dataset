#!/bin/bash
#SBATCH --job-name=qwen35-fast
#SBATCH --account=torch_pr_1269_tandon_advanced
#SBATCH --partition=h200_tandon
#SBATCH --array=0-3%4
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --gres=gpu:h200:1
#SBATCH --mem=120G
#SBATCH --time=24:00:00
#SBATCH --requeue
#SBATCH --output=/scratch/ft2335/dataset-observable/experiments/qwen35-3prompt-10attempt-v1/fast-%A-%a.log
set -euo pipefail
cd /scratch/ft2335/dataset-observable
export HF_HUB_OFFLINE=1 TRANSFORMERS_OFFLINE=1 TOKENIZERS_PARALLELISM=false OMP_NUM_THREADS=4
export HF_HOME="$PWD/.cache/huggingface"
export TMPDIR="$PWD/.cache/qwen35-fast-${SLURM_ARRAY_JOB_ID}-${SLURM_ARRAY_TASK_ID}"
mkdir -p "$TMPDIR"
test -f experiments/qwen35-3prompt-10attempt-v1/download.complete
pids=()
for local_rank in 0 1 2; do
  rank=$((SLURM_ARRAY_TASK_ID * 3 + local_rank))
  .cache/qwen35-venv/bin/python -u scripts/generate_qwen35_3prompt.py \
    --output experiments/qwen35-3prompt-10attempt-v1 --attempts 10 \
    --rank "$rank" --world-size 12 \
    > "experiments/qwen35-3prompt-10attempt-v1/fast-${SLURM_ARRAY_JOB_ID}-rank-${rank}.log" 2>&1 &
  pids+=("$!")
done
status=0
for pid in "${pids[@]}"; do
  wait "$pid" || status=$?
done
exit "$status"
