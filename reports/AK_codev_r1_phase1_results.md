# AK — CodeV-R1 Phase 1 full benchmark results

**Generated:** 2026-09-29T04:47:34.533332+00:00
**Matrix status:** complete

## Release-readiness warning

**The generation/evaluation matrix is complete, but the public CDC benchmark is not release-ready.** The enhanced 44-circuit typed CDC testbench and structural-lint artifacts described in the September report are absent from this checkout. Current `strict_pass` is an open-source heuristic composite, not a validated first-pass CDC-screen result. Do not publish it as a CDC-clean rate. In addition, 28 testbench-emitted `TIMEOUT` outcomes are currently folded into the functional/protocol primary bucket; raw logs preserve them, but the result schema and table must be normalized before release. See `reports/AK_PUBLIC_CDC_RELEASE_GAP_AND_PLAN.md` for the blocking gaps, ten-rule target, and remediation plan.

## Scope and protocol

Model: `zhuyaoyu/CodeV-R1-RL-Qwen-7B`, revision `286cf433f596f1b8525529c1163eb81c19425c22`. The full matrix is 44 circuits (11 `pilot_verified`, 33 `imported_unverified`) × 3 prompt families × 3 independent seeds = 396 planned attempts. Sampling is temperature 0.2, top-p 0.95, maximum 16384 output tokens, and seeds 1001–1003, with the checked-in CodeV reasoning-format system prompt. The 16384-token setting matches the CodeV-R1 paper and was selected after the prepared 8192-token protocol truncated most responses during reasoning; that preliminary matrix is archived and excluded from these results.

Open-source scoring uses Icarus Verilog for compile/simulation and a repository-owned source-level checker plus each benchmark SDC for conservative direct-crossing triage. `Strict pass` means compile pass, canonical testbench pass, completed structural analysis, valid SDC clock context, and zero structural findings. This is reproducible error-catching evidence, not proof of metastability safety and not a JasperGold-equivalent CDC-clean result.

## Prompt inventory

| Prompt key | Files | Word range | Aggregate SHA-256 |
|---|---:|---:|---|
| functional | 44 | 100–814 | `bac7911f696c10d1dd4db22371713619198d50c2cfa7f5c1edb5a80a9999c045` |
| cdc_explicit | 44 | 142–856 | `f56fdf42f664a08eceac0e14a55932a06172682a1b5d2ac09b85abf529d72245` |
| observable | 44 | 80–496 | `505c53c30ef9a76c089147c63ec83a91d3eae60775308482d40a3e720306ac09` |

The checked-in keys map to Prompt Set 1 (`functional`, collaborator checklist), Prompt Set 2 (`cdc_explicit`, collaborator long prompt with an explicit CDC requirement), and Prompt Set 3 (`observable`, supervisor short human-style prompt). The checked-in Set 2 files remain visibly labeled/checklist-structured rather than unstructured; results below identify the immutable repository key to avoid silently relabeling the actual inputs.

## Open-source golden calibration

The identical flow was calibrated on 44 checked-in golden tops: compile 41/44, functional 41/44, structural-clean 35/44, and strict 35/44. `apb_regs` and `cdc_2phase_clearable` are predeclared Icarus tool incompatibilities and are reported as tool errors for every prompt, not model failures. Remaining golden structural warnings and incomplete SDCs establish the interpretation ceiling of the heuristic check.

## Measured outcomes

| Prompt | Saved RTL | Generation errors | Tool errors | Compile pass | Functional pass | Timeouts | Dynamic CDC/protocol failures | Structural analyzed | Structural clean | CDC-evidence attempts | Structural findings | Strict pass | Functional pass@1 | Strict pass@1 | Functional pass@3 | Strict pass@3 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| functional | 88/132 | 44 | 3 | 73/88 | 40/88 | 7 | 1 | 73/88 | 57/88 | 13 | 34 | 34/132 | 0.303 | 0.258 | 0.523 | 0.386 |
| cdc_explicit | 95/132 | 37 | 4 | 76/95 | 41/95 | 9 | 0 | 76/95 | 60/95 | 14 | 34 | 39/132 | 0.311 | 0.295 | 0.432 | 0.386 |
| observable | 95/132 | 37 | 2 | 65/95 | 40/95 | 5 | 0 | 65/95 | 47/95 | 13 | 35 | 33/132 | 0.303 | 0.250 | 0.432 | 0.364 |

## Prior-report-compatible aggregate

Across 396 attempts:

- 118 generation/extraction failures
- 55 compilation failures
- 71 primary functional/protocol failures
- 1 primary dynamic CDC/reset flag(s)
- 106 strict passes
- 15 primary structural CDC warnings
- 21 timeouts
- 9 tool errors
- 40 attempts with automatically attributed CDC/reset evidence
- 214 attempts compiled; 121 passed the canonical functional testbench

This uses the September report's primary-outcome vocabulary. Generation/extraction failures are kept separate because the earlier model run did not contain an equivalent complete generation matrix.

## Prompt comparison

- Prompt Set 1 (`functional`) achieved functional pass@1 30.3%, strict pass@1 25.8%, functional pass@3 52.3%, and strict pass@3 38.6%.
- Prompt Set 2 (`cdc_explicit`) achieved functional pass@1 31.1%, strict pass@1 29.5%, functional pass@3 43.2%, and strict pass@3 38.6%.
- Prompt Set 3 (`observable`) achieved functional pass@1 30.3%, strict pass@1 25.0%, functional pass@3 43.2%, and strict pass@3 36.4%.

Set 2 has the highest strict pass@1 by 3.7 percentage points over Set 1 and 4.5 points over Set 3. At pass@3, Sets 1 and 2 tie on strict pass rate; Set 1 has the highest functional pass@3. These are descriptive comparisons over the same balanced matrix, not causal prompt-effect estimates.

## Primary-outcome breakdown

- `functional`: compile_failure=12, dynamic_cdc_protocol_failure=1, functional_protocol_failure=25, generation_error=44, strict_pass=34, structural_cdc_warning=6, timeout=7, tool_error=3
- `cdc_explicit`: compile_failure=15, functional_protocol_failure=26, generation_error=37, strict_pass=39, structural_cdc_warning=2, timeout=9, tool_error=4
- `observable`: compile_failure=28, functional_protocol_failure=20, generation_error=37, strict_pass=33, structural_cdc_warning=7, timeout=5, tool_error=2

## Interpretation boundary

The 33 `imported_unverified` circuits are reported separately in raw records through `benchmark_status`; aggregate prompt comparisons are descriptive because circuit specifications and testbench strength are not yet frozen. A structural warning is an automatically detected review item, not an adjudicated CDC root cause. Phase 2 will inspect failed candidates and classify functional versus CDC-specific causes.
