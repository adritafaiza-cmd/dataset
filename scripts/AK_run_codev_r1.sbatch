#!/usr/bin/env bash
#SBATCH --job-name=AK_codev_r1
#SBATCH --account=torch_pr_1269_tandon_advanced
#SBATCH --partition=h200_tandon
#SBATCH --qos=gpu48
#SBATCH --gres=gpu:1
#SBATCH --constraint=h200
#SBATCH --cpus-per-task=16
#SBATCH --mem=128G
#SBATCH --time=24:00:00
#SBATCH --output=/scratch/atk331/dataset/build/AK_codev_r1/slurm-%j.out

set -euo pipefail

ROOT=/scratch/atk331/dataset
IMAGE="$SLURM_TMPDIR/vllm-openai-v0.10.2"
TOOLS="$SLURM_TMPDIR/AK_codev_tools/bin"
MODEL=zhuyaoyu/CodeV-R1-RL-Qwen-7B
REVISION=286cf433f596f1b8525529c1163eb81c19425c22
PORT=8000
WORKERS=16

cd "$ROOT"
mkdir -p "$ROOT/build/AK_codev_r1"
module load singularity-ce/4.5.1
module load anaconda3/2026.07

export SINGULARITY_CACHEDIR=/scratch/atk331/singularity-cache
export SINGULARITY_TMPDIR="$SLURM_TMPDIR/singularity-tmp"
export CONDA_PKGS_DIRS=/scratch/atk331/conda-pkgs
export CONDA_ENVS_PATH="$SLURM_TMPDIR/conda-envs"
export CONDA_REGISTER_ENVS=false
mkdir -p "$SINGULARITY_TMPDIR" "$CONDA_ENVS_PATH"

singularity build --sandbox "$IMAGE" docker://vllm/vllm-openai:v0.10.2
conda create -y -p "$SLURM_TMPDIR/AK_codev_tools" \
  --override-channels -c conda-forge iverilog
export PATH="$TOOLS:$PATH"
python3 scripts/AK_eval_codev_r1_open.py --calibrate-golden --timeout 120

export HF_HOME=/scratch/atk331/huggingface-cache
export HUGGINGFACE_HUB_CACHE="$HF_HOME/hub"
export XDG_CACHE_HOME="$SLURM_TMPDIR/cache"
export FLASHINFER_WORKSPACE_BASE="$SLURM_TMPDIR/flashinfer"
export TORCH_EXTENSIONS_DIR="$SLURM_TMPDIR/torch-extensions"
export TRITON_CACHE_DIR="$SLURM_TMPDIR/triton"
export VLLM_CACHE_ROOT="$SLURM_TMPDIR/vllm-cache"
export SINGULARITYENV_HF_HOME="$HF_HOME"
export SINGULARITYENV_HUGGINGFACE_HUB_CACHE="$HUGGINGFACE_HUB_CACHE"
export SINGULARITYENV_XDG_CACHE_HOME="$XDG_CACHE_HOME"
export SINGULARITYENV_FLASHINFER_WORKSPACE_BASE="$FLASHINFER_WORKSPACE_BASE"
export SINGULARITYENV_TORCH_EXTENSIONS_DIR="$TORCH_EXTENSIONS_DIR"
export SINGULARITYENV_TRITON_CACHE_DIR="$TRITON_CACHE_DIR"
export SINGULARITYENV_VLLM_CACHE_ROOT="$VLLM_CACHE_ROOT"
export VLLM_WORKER_MULTIPROC_METHOD=spawn
export VLLM_NO_USAGE_STATS=1
export TOKENIZERS_PARALLELISM=false
export SINGULARITYENV_VLLM_NO_USAGE_STATS=1
mkdir -p "$XDG_CACHE_HOME" "$FLASHINFER_WORKSPACE_BASE" \
  "$TORCH_EXTENSIONS_DIR" "$TRITON_CACHE_DIR" "$VLLM_CACHE_ROOT"

SERVER_LOG="$ROOT/build/AK_codev_r1/vllm-${SLURM_JOB_ID}.log"
singularity exec --nv --bind /scratch:/scratch "$IMAGE" \
  vllm serve "$MODEL" \
  --revision "$REVISION" \
  --served-model-name "$MODEL" \
  --dtype bfloat16 \
  --max-model-len 32768 \
  --max-num-seqs 32 \
  --gpu-memory-utilization 0.90 \
  --host 127.0.0.1 \
  --port "$PORT" >"$SERVER_LOG" 2>&1 &
SERVER_PID=$!
cleanup() {
  kill "$SERVER_PID" 2>/dev/null || true
  wait "$SERVER_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

for _ in $(seq 1 180); do
  if curl --silent --fail "http://127.0.0.1:${PORT}/v1/models" >/dev/null; then
    break
  fi
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "vLLM server exited before becoming ready; see $SERVER_LOG" >&2
    exit 1
  fi
  sleep 10
done
curl --silent --fail "http://127.0.0.1:${PORT}/v1/models" >/dev/null

mapfile -t CIRCUITS < <(
  find experiments/prompts -maxdepth 1 -type f -name '*.functional.md' -printf '%f\n' \
    | sed 's/\.functional\.md$//' \
    | sort
)
if [[ "${#CIRCUITS[@]}" -ne 44 ]]; then
  echo "Expected 44 circuits, found ${#CIRCUITS[@]}" >&2
  exit 1
fi

export ROOT MODEL REVISION PORT
printf '%s\0' "${CIRCUITS[@]}" | xargs -0 -n1 -P "$WORKERS" bash -c '
  python3 "$ROOT/scripts/run_codev_r1.py" generate \
    --circuit "$1" \
    --attempts 3 \
    --base-url "http://127.0.0.1:${PORT}/v1" \
    --temperature 0.2 \
    --top-p 0.95 \
    --max-tokens 16384 \
    --seed 1000 \
    --timeout 1200 \
    --system-prompt official \
    --model-revision "$REVISION" \
    --continue-on-error
' _

cleanup
trap - EXIT INT TERM

python3 scripts/AK_eval_codev_r1_open.py --timeout 120
python3 scripts/AK_report_codev_r1.py

python3 - <<'PY'
import json
from pathlib import Path

root = Path("experiments/codev-r1-rl-qwen-7b")
metadata = list(root.glob("*/*/attempt-*/metadata.json"))
generated = [p for p in metadata if json.loads(p.read_text()).get("generation_status") == "generated"]
results = list(root.glob("*/*/attempt-*/results.json"))
print(f"AK_MATRIX metadata={len(metadata)} generated={len(generated)} results={len(results)}")
if len(metadata) != 396 or len(results) != len(generated):
    raise SystemExit("incomplete CodeV-R1 matrix")
PY
