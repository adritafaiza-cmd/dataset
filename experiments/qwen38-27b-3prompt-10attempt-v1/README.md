# Qwen 3.8 27B: completed RTL generation

This run contains 1,320 completed generations: 44 circuits × three prompt types
(`functional`, `cdc_explicit`, `observable`) × seeds 1–10. Generation finished
on October 31, 2026. Completion does not imply compilation or formal correctness.

## Generated code

Each RTL file is at:

```text
<circuit>/<prompt_type>/attempt-<001..010>/generated/<circuit>.sv
```

Each attempt also includes the frozen prompt, rendered request, raw response,
response JSON, metadata, and a `complete.json` containing SHA-256 hashes of all
six artifacts. Run environment records and worker progress are included.

## Check completion

From the repository root:

```bash
python3 scripts/qwen38_27b_progress.py
```

Expected result: 1,320 completed, 132 prompt combinations, and no invalid markers.
This command verifies generated RTL hashes.

## Generation code

- `scripts/download_qwen38_27b.py`: downloads the pinned checkpoint.
- `scripts/generate_qwen38_27b_3prompt.py`: generates candidates with resumable,
  hash-checked completion records.
- `scripts/qwen38_27b_download.sbatch`: cluster download job.
- `scripts/qwen38_27b_3prompt.sbatch`: eight-worker GPU generation array.

Model: `Qwen/Qwen3.8-27B`, revision
`1d4bf0f2ff6012fd82039f2fa52739d0dd7c60c0`, BF16. Sampling uses temperature
0.2, top-p 0.95, top-k 0, and a maximum of 8,192 new tokens, with thinking
disabled. See `requirements-resolved.txt` and `runs/*/environment.json` for
the recorded environment. Model weights are not included.

The Slurm scripts use the original cluster paths and account; adapt those to
your environment before submitting. With the dependencies installed and the
checkpoint downloaded, a generation invocation is:

```bash
python3 scripts/generate_qwen38_27b_3prompt.py \
  --output experiments/qwen38-27b-3prompt-10attempt-v1 \
  --attempts 10 --rank 0 --world-size 8
```

Run ranks 0–7 separately with one GPU each. Completion identities include
absolute model paths, so use a fresh output directory to regenerate on another
machine.
