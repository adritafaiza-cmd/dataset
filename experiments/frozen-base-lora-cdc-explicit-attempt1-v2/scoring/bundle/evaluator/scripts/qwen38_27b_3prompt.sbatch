#!/bin/bash
#SBATCH --job-name=qwen38-27b-44x3x10
#SBATCH --account=torch_pr_1269_tandon_advanced
#SBATCH --partition=h200_tandon
#SBATCH --array=0-7%8
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --gres=gpu:h200:1
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --requeue
#SBATCH --signal=B:USR1@180
#SBATCH --output=/scratch/ft2335/dataset-observable/experiments/qwen38-27b-3prompt-10attempt-v1/generate-%A-%a.log
set -euo pipefail
cd /scratch/ft2335/dataset-observable
export HF_HUB_OFFLINE=1 TRANSFORMERS_OFFLINE=1 TOKENIZERS_PARALLELISM=false OMP_NUM_THREADS=4
export HF_HOME="$PWD/.cache/huggingface"
export TMPDIR="$PWD/.cache/qwen38-27b-tmp-${SLURM_ARRAY_JOB_ID}-${SLURM_ARRAY_TASK_ID}"
mkdir -p "$TMPDIR"
test -f experiments/qwen38-27b-3prompt-10attempt-v1/download.complete
resume() {
  scontrol requeue "${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
  exit 0
}
trap resume USR1
set +e
timeout --signal=TERM --kill-after=60s 23h \
  .cache/qwen38-venv/bin/python -u scripts/generate_qwen38_27b_3prompt.py \
  --output experiments/qwen38-27b-3prompt-10attempt-v1 --attempts 10 \
  --rank "$SLURM_ARRAY_TASK_ID" --world-size 8 &
worker=$!
wait "$worker"
status=$?
set -e
if [[ "$status" == 124 || "$status" == 137 ]]; then resume; fi
if [[ "$status" != 0 && "${SLURM_RESTART_COUNT:-0}" -lt 3 ]]; then
  sleep 30
  resume
fi
exit "$status"
