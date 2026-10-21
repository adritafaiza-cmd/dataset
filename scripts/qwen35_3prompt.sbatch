#!/bin/bash
#SBATCH --job-name=qwen35-44x3x10
#SBATCH --account=torch_pr_1269_tandon_advanced
#SBATCH --partition=h200_tandon
#SBATCH --array=0-3%4
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --gres=gpu:h200:1
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --requeue
#SBATCH --signal=B:USR1@180
#SBATCH --output=/scratch/ft2335/dataset-observable/experiments/qwen35-3prompt-10attempt-v1/generate-%A-%a.log
set -euo pipefail
cd /scratch/ft2335/dataset-observable
export HF_HUB_OFFLINE=1 TRANSFORMERS_OFFLINE=1 TOKENIZERS_PARALLELISM=false OMP_NUM_THREADS=4
export HF_HOME="$PWD/.cache/huggingface"
export TMPDIR="$PWD/.cache/qwen35-tmp-${SLURM_ARRAY_JOB_ID}-${SLURM_ARRAY_TASK_ID}"
mkdir -p "$TMPDIR"
test -f experiments/qwen35-3prompt-10attempt-v1/download.complete
resume() {
  scontrol requeue "${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
  exit 0
}
trap resume USR1
set +e
timeout --signal=TERM --kill-after=60s 23h \
  .cache/qwen35-venv/bin/python -u scripts/generate_qwen35_3prompt.py \
  --output experiments/qwen35-3prompt-10attempt-v1 --attempts 10 \
  --rank "$SLURM_ARRAY_TASK_ID" --world-size 4 &
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
