# AK — CodeV-R1 benchmark

**Status:** Phase 1 full matrix complete; public CDC release blocked. The
canonical measured report is
[`AK_codev_r1_phase1_results.md`](AK_codev_r1_phase1_results.md). The current
checkout lacks the enhanced typed CDC testbench/lint suite described in the
September report, so `strict_pass` must not be published as a validated
CDC-clean or first-pass-screen rate. The blocker and repair plan are in
[`AK_PUBLIC_CDC_RELEASE_GAP_AND_PLAN.md`](AK_PUBLIC_CDC_RELEASE_GAP_AND_PLAN.md).

## Executed protocol

- Model: `zhuyaoyu/CodeV-R1-RL-Qwen-7B`
- Pinned revision: `286cf433f596f1b8525529c1163eb81c19425c22`
- Backend: official `vllm/vllm-openai:v0.10.2` container on one H200
- Scope: 44 circuits × 3 checked-in prompt families × 3 independent seeds =
  396 attempts
- Sampling: temperature 0.2, top-p 0.95, maximum 16,384 output tokens,
  seeds 1001–1003, official CodeV reasoning-format system prompt
- SLURM job: `18737893`, completed with exit code 0 in 1:35:01 on `gh113`

Every attempt preserves the exact prompt, prompt hash, request, full response,
generation metadata, and either extracted RTL or a generation-error record under
`experiments/codev-r1-rl-qwen-7b/`. The matrix contains 396 metadata/response
records, 278 extracted RTL candidates, and 278 evaluator results.

The initially prepared 8,192-token protocol was also completed, but 329/396
responses exhausted the output budget before emitting a complete requested top
module. It is archived under
`experiments/codev-r1-rl-qwen-7b-8192-truncated-18734015/` and excluded from the
final comparison. Its report is
[`AK_codev_r1_preliminary_8192_truncated_18734015.md`](AK_codev_r1_preliminary_8192_truncated_18734015.md).

## Open-source evaluation

JasperGold and Xcelium are unavailable on this cluster and were not invoked.
The supervisor-owned evaluator uses Icarus Verilog 13 for compilation and the
checked-in canonical testbench, recognizes embedded protocol/CDC assertion
markers, checks each checked-in SDC's clock context, and runs conservative
source-level direct-crossing triage.

The identical evaluator was calibrated on all 44 golden tops. Icarus compiled
and functionally passed 41/44; the heuristic strict criterion passed 35/44.
Consequently, a reported strict pass is reproducible open-source evidence, not
proof of silicon metastability safety or a JasperGold-equivalent CDC-clean
result. `apb_regs` and `cdc_2phase_clearable` are predeclared Icarus
incompatibilities and remain tool errors rather than model failures.

## Final prompt comparison

| Prompt set / repository key | Saved RTL | Compile pass | Functional pass | Strict pass | Functional pass@1 | Strict pass@1 | Functional pass@3 | Strict pass@3 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Set 1 / `functional` | 88/132 | 73/88 | 40/88 | 34/132 | 30.3% | 25.8% | 52.3% | 38.6% |
| Set 2 / `cdc_explicit` | 95/132 | 76/95 | 41/95 | 39/132 | 31.1% | 29.5% | 43.2% | 38.6% |
| Set 3 / `observable` | 95/132 | 65/95 | 40/95 | 33/132 | 30.3% | 25.0% | 43.2% | 36.4% |

Set 2 has the highest strict pass@1. Sets 1 and 2 tie on strict pass@3, while
Set 1 has the highest functional pass@3. These are descriptive balanced-matrix
comparisons; 33 of the 44 circuit manifests remain `imported_unverified`, so
they are not causal prompt-effect or publication-ready model claims.

The repository's Set 2 files are long and contain an explicit CDC requirement,
but remain visibly labeled/checklist-structured. Reports retain the immutable
`cdc_explicit` key rather than silently describing the actual checked-in files
as unstructured.

## Interpretation boundary

Across the full matrix there were 118 generation/extraction failures, 55
compilation failures, 71 primary functional/protocol failures, one primary
dynamic CDC/reset failure, 15 primary structural warnings, 21 timeouts, nine
tool errors, and 106 strict passes. Forty attempts contained automatically
attributed CDC/reset evidence. A structural warning is a review item, not an
adjudicated root cause; failed-candidate root-cause classification is reserved
for Phase 2.

Before Phase 2 interpretation or public release, the benchmark needs the
documented ten-rule open-source first-pass CDC contract: typed dynamic monitors,
elaborated-netlist structural checks, SDC/clock/reset contract validation,
normalized evidence fields, and rule-targeted mutation testing. Passing that
future screen will mean only that no published basic rule fired; it will not
claim complete CDC safety or replace implementation-aware signoff.
