# AK — CodeV-R1 benchmark

**Status:** Protocol prepared; no CodeV-R1 generations or benchmark scores have been measured here. A dash, `N/A`, or `not run` below is not a failure or a CDC-clean result.

## What is being tested

The model is the **RL** release `zhuyaoyu/CodeV-R1-RL-Qwen-7B`, not the distillation checkpoint. The authors' repository is https://github.com/iprc-dip/CodeV-R1 and its paper is from **2025** (arXiv:2505.24183). Record the **operator-supplied** Hugging Face revision in each attempt's metadata; the client cannot independently attest the running server's weights, and an unspecified revision is recorded as unknown. No project reference RTL, testbench, or prior failure is provided to the model.

This is a separate one-shot experiment under `experiments/codev-r1-rl-qwen-7b/<circuit>/<prompt>/attempt-NNN/`. Each attempt saves its exact prompt, hash, request, full response, extracted RTL, model/decoding metadata, and any generation error. Prompt types are `functional`, `cdc_explicit`, and `observable`. Default scope: the same three pilot circuits used in the earliest model comparison (`cdc_2phase`, `async_fifo`, `apbxclk`), three independent attempts per prompt: **27 planned outputs**. `--all` expands to 44 circuits; the 33 manifests marked `imported_unverified` must be identified separately.

The generation adapter is `scripts/run_codev_r1.py`. It talks only to a local OpenAI-compatible vLLM server and uses the model card's reasoning-format system instruction for all three prompt types by default; `--system-prompt none` is a separately labeled protocol. The default sampling settings (temperature 0.2, top-p 0.95, 8192 maximum output tokens) follow this repository's earlier runner, **not** the model paper's 0.6 / 16384-token / 20-sample evaluation. Changing settings defines a different run; record the exact settings before making cross-model claims.

## How to run the full model on HPC

Use a machine with enough GPU memory for the unquantized ~15.2 GB RL checkpoint **plus inference overhead** (this machine's 8 GB GPU is insufficient). Do not substitute the smaller distill model or an unreported quantization. Install a compatible, reviewed vLLM version in an isolated environment as directed by the authors; keep its version, GPU, and checkpoint revision in the run notes. From the repository root, start the model server in one terminal:

```bash
vllm serve zhuyaoyu/CodeV-R1-RL-Qwen-7B --revision 286cf433f596f1b8525529c1163eb81c19425c22 --served-model-name zhuyaoyu/CodeV-R1-RL-Qwen-7B --max-model-len 16384 --host 127.0.0.1 --port 8000
```

In another terminal, also from the repository root:

```bash
python3 scripts/run_codev_r1.py plan
python3 scripts/run_codev_r1.py generate --attempts 3 --model-revision 286cf433f596f1b8525529c1163eb81c19425c22
python3 scripts/run_codev_r1.py report --attempts 3
```

`--circuit <name>` restricts to a named benchmark; `--all` runs the complete 44 × 3 matrix. Existing attempts (including generation errors) are skipped, not edited. The `report` command refreshes only the **Measured outcomes** section of this file; keep manual interpretation elsewhere. Do not compare a partial matrix to another model as though it were balanced. No credentials or private model weights belong in this repository.

Transfer the saved `experiments/codev-r1-rl-qwen-7b/` tree to a machine with licensed Xcelium/JasperGold, then score the generated RTL **using the existing model-independent evaluator**:

```bash
python3 scripts/eval_all_generated.py --model-dir experiments/codev-r1-rl-qwen-7b
python3 scripts/run_codev_r1.py report --attempts 3
```

The evaluator substitutes each generated top into the benchmark's existing `sim/run.sh`, using the **same checked-in TB and helper RTL** as prior model runs; JasperGold runs only after a functional pass. Its raw Xcelium/Jasper output goes to `build/` (ignored by Git) and per-attempt `results.json` lives alongside the candidate. Run `report --all --attempts 3` for a full matrix. Do not run this Xcelium/Jasper scoring command on a generation-only HPC node without those tools: a missing tool is not a model compile failure. Rerunning the existing evaluator replaces its prior per-attempt result and build logs, so retain a snapshot before any rerun.

## Metrics and comparability

| Stage | Meaning |
|---|---|
| Saved RTL | A response with an extractable requested module; generation errors are separate from compiler failures. |
| Tool errors | Infrastructure failures are separate from a model's compile or CDC failures; raw logs still require review. |
| Compile pass | `compile_ok` from the shared Xcelium compile/elaborate stage. |
| Functional pass | `simulate_ok` from the same canonical benchmark TB and pass marker used for earlier models. |
| Jasper analyzed | Functional-pass candidates for which Jasper finished and reported CDC/RDC counts. |
| CDC/RDC errors | Sums of reported errors **only** among completed Jasper analyses; an unrun analysis is unknown, not zero. |
| Functional+Jasper clean | Functional pass and the evaluator's `cdc_clean`; neither compilation nor simulation alone qualifies. |
| Pass@1 / pass@k | The existing unbiased estimator is applied per circuit and then averaged across circuits (macro rate); shown as `N/A` for an incomplete stage. |

The September 20–21 progress report used an **additional typed enhanced-TB/lint suite** and described its own `strict pass`. Those artifacts are not in this clone; this report must **not** equate a canonical-TB/Jasper pass with that separate strict-pass label or assign CDC root causes from simulation alone. A model's RTLLM/VerilogEval score in its paper is not a score on this dataset.

## Measured outcomes

Scope: 3 circuits × 3 prompts × 3 attempts = 27 planned generations.

| Prompt | Saved RTL | Generation errors | Tool errors | Compile pass | Functional pass | Timeouts | Jasper analyzed | CDC errors | RDC errors | Functional+Jasper clean | Functional pass@1 | Combined pass@1 | Functional pass@3 | Combined pass@3 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| functional | 0/9 | not run | not run | not run | not complete | not run | not run | not run | not run | not complete | N/A | N/A | N/A | N/A |
| cdc_explicit | 0/9 | not run | not run | not run | not complete | not run | not run | not run | not run | not complete | N/A | N/A | N/A | N/A |
| observable | 0/9 | not run | not run | not run | not complete | not run | not run | not run | not run | not complete | N/A | N/A | N/A | N/A |

Per circuit (saved / functional / functional+Jasper clean; '—' means the stage is not fully evaluated):

| Circuit | Manifest | Functional | CDC-explicit | Observable |
|---|---|---:|---:|---:|
| cdc_2phase | pilot_verified | 0/—/— | 0/—/— | 0/—/— |
| async_fifo | pilot_verified | 0/—/— | 0/—/— | 0/—/— |
| apbxclk | pilot_verified | 0/—/— | 0/—/— | 0/—/— |

A dash/N/A means **unmeasured**, never zero CDC errors or a model failure. This table uses the checked-in canonical TB and the Xcelium/Jasper evaluator, not the missing September typed-TB suite.

## Interpretation

No CodeV-R1 pass rate, functional gap, or CDC/RDC gap can currently be claimed. In particular, this local machine has Icarus but neither `xrun` nor `jg`, and the model has not been loaded here. Review the completed rows, raw tool reports, golden baselines, and imported-circuit exclusions before making a publication comparison.
