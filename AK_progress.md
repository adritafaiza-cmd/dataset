# AK progress log

## Phase 1 — CodeV-R1 benchmark execution complete; release-readiness clarification open

### 2026-09-28: repository and protocol verification

- Read `AGENTS.md`, the repository `README.md`, `reports/progress-track/README.md`, and the full 20–21 September progress report.
- Confirmed the benchmark inventory is 44 circuits: 11 manifests marked `pilot_verified` and 33 marked `imported_unverified`.
- Confirmed a complete 44-file matrix for each checked-in prompt key: `functional`, `cdc_explicit`, and `observable`. The first two are collaborator prompt families; commit `90d653e` identifies `observable` as the supervisor's shorter human-style variant.
- Confirmed the pre-existing CodeV-R1 protocol targets `zhuyaoyu/CodeV-R1-RL-Qwen-7B` revision `286cf433f596f1b8525529c1163eb81c19425c22`, uses three attempts per circuit/prompt, and therefore defines a 44 × 3 × 3 = 396-attempt full matrix.
- Verified the valid Torch SLURM account is `torch_pr_1269_tandon_advanced`; available H200 resources were queried from the live scheduler. No partition was invented.
- Verified the repository does not contain the separate enhanced-TB/lint directories described in the September narrative report. The available assets are 44 canonical testbenches, embedded assertion monitors in selected testbenches, and 44 SDC files. JasperGold/Xcelium scoring was not used.

### 2026-09-28: supervisor-owned implementation

- Added `scripts/AK_run_codev_r1.sbatch`, an H200 SLURM job that isolates vLLM in the official `vllm/vllm-openai:v0.10.2` container, serves the pinned CodeV-R1 checkpoint, runs 16 concurrent circuit workers, preserves all prompts/responses/metadata, and scores every extracted candidate.
- Added `scripts/AK_eval_codev_r1_open.py`, which translates the checked-in simulation commands to Icarus Verilog, runs the canonical testbenches, recognizes pass/fail/timeout and embedded CDC/protocol assertion evidence, checks SDC clock coverage, and performs conservative source-level direct-crossing triage. Its structural result is explicitly not treated as metastability proof or a JasperGold-equivalent conclusion.
- Added `scripts/AK_report_codev_r1.py`, which renders prompt-level saved/compile/functional/structural/strict metrics and macro pass@1/pass@3 values into `reports/AK_codev_r1_phase1_results.md`.
- Kept all collaborator scripts untouched. The only pre-existing executable exercised directly was the supervisor-owned CodeV-R1 unit test/runner path permitted by the task.

### 2026-09-28: validation and calibration

- Ran `python3 scripts/test_run_codev_r1.py -v`: 6/6 tests passed, including loopback vLLM API behavior, prompt/metadata preservation, RTL extraction, evaluator substitution, and incomplete-matrix reporting.
- Syntax-checked the new Python and SLURM scripts.
- Installed/used Icarus Verilog 13.0 from an isolated conda-forge environment. Default Conda/Singularity caches initially hit home and `/tmp` limits; both caches and compute-job temporary assembly were redirected to scratch or `$SLURM_TMPDIR`. No model attempt was started during these infrastructure retries.
- Calibrated the identical evaluator on all 44 checked-in golden tops; raw records are in `build/AK_codev_r1/golden_calibration.json`.
- Golden calibration result: 41/44 compiled and functionally passed with Icarus. `apb_regs` and `cdc_2phase_clearable` are predeclared Icarus tool incompatibilities and will be tool errors, not model failures. The `apb_cdc` golden top uses duplicate declarations rejected by Icarus; standards-compliant generated replacements remain scoreable.
- Structural/SDC strict calibration passed 35/44 goldens. This known ceiling comes from conservative direct-crossing warnings on some bundled-data/handshake structures and incomplete SDC clock relationships for two imported circuits; such warnings will remain automated review evidence rather than adjudicated CDC root causes.

### 2026-09-28: HPC startup qualification

- Used only the supervisor-owned `scripts/AK_run_codev_r1.sbatch` and the explicitly permitted CodeV-R1 runner/test paths. No collaborator script was modified or executed.
- Submitted four startup-qualification jobs that ended before generation began: `18710730` (Singularity SIF creation lacked `mksquashfs`), `18710847` (Conda attempted home registration), `18733020` (FlashInfer attempted a home cache), and `18733351` (the first FlashInfer environment-variable name was incorrect).
- Corrected the supervisor SLURM script after each infrastructure-only failure: switched to a job-local Singularity sandbox, isolated Conda under `$SLURM_TMPDIR`, and verified/forwarded the exact `FLASHINFER_WORKSPACE_BASE` setting plus XDG, Torch, Triton, vLLM, Hugging Face, and Singularity cache paths. No benchmark output was counted from these jobs.

### 2026-09-28: excluded 8,192-token calibration matrix

- SLURM job `18734015` completed successfully on `gh120` with exit code 0 in 41:02 using the initially prepared 8,192-output-token setting.
- It completed all 396 generation attempts but extracted only 67 requested top modules. The other 329 responses hit the output limit during reasoning and ended without a complete requested top module; all 118 later failures in the corrected run likewise have an explicit `length` finish reason, confirming the runner distinguishes output truncation from compiler failure.
- Evaluated all 67 extracted candidates and generated the preliminary report. This run was then archived intact as `experiments/codev-r1-rl-qwen-7b-8192-truncated-18734015/` with report `reports/AK_codev_r1_preliminary_8192_truncated_18734015.md`.
- Marked this matrix excluded from all final prompt comparisons because its token budget did not match the CodeV-R1 paper's 16,384-token generation budget and caused dominant reasoning truncation.

### 2026-09-28: corrected full benchmark execution

- Updated the supervisor SLURM job to serve with a 32,768-token model context and request at most 16,384 output tokens. The job retained temperature 0.2, top-p 0.95, official CodeV reasoning-format system prompt, and deterministic seeds 1001–1003.
- `sbatch --test-only` accepted the corrected submission. SLURM job `18737893` then completed successfully on H200 node `gh113` with exit code 0 in 1:35:01.
- Verified all 396 attempt metadata records contain model `zhuyaoyu/CodeV-R1-RL-Qwen-7B`, pinned revision `286cf433f596f1b8525529c1163eb81c19425c22`, maximum 16,384 output tokens, temperature 0.2, top-p 0.95, and official system prompt. Each seed occurs exactly 132 times.
- Verified matrix integrity: 396 saved prompts/requests/responses/metadata records; 278 extracted RTL candidates; 278 corresponding `results.json` records; 118 generation/extraction failures. Every extracted candidate ended with `finish_reason=stop`; every failed extraction ended with `finish_reason=length` at exactly 16,384 completion tokens.
- The 278 successful extractions used 4,736–14,956 completion tokens, mean 9,759.7. These raw records remain under `experiments/codev-r1-rl-qwen-7b/`.

### 2026-09-28: final measured results

- Generated `reports/AK_codev_r1_phase1_results.md`, with the same primary-outcome vocabulary used by the September 20–21 report plus saved-RTL, extraction, Icarus, structural, and pass@k columns.
- Aggregate outcomes across 396 attempts: 118 generation/extraction failures, 55 compilation failures, 71 primary functional/protocol failures, one primary dynamic CDC/reset failure, 15 primary structural CDC warnings, 21 timeouts, nine tool errors, and 106 strict passes. A total of 214 attempts compiled, 121 passed the canonical functional testbench, and 40 contained automatically attributed CDC/reset evidence.
- Prompt Set 1 / `functional`: 88/132 saved RTL, 73/88 compile passes, 40/88 functional passes, 34/132 strict passes; functional pass@1 30.3%, strict pass@1 25.8%, functional pass@3 52.3%, strict pass@3 38.6%.
- Prompt Set 2 / `cdc_explicit`: 95/132 saved RTL, 76/95 compile passes, 41/95 functional passes, 39/132 strict passes; functional pass@1 31.1%, strict pass@1 29.5%, functional pass@3 43.2%, strict pass@3 38.6%.
- Prompt Set 3 / `observable`: 95/132 saved RTL, 65/95 compile passes, 40/95 functional passes, 33/132 strict passes; functional pass@1 30.3%, strict pass@1 25.0%, functional pass@3 43.2%, strict pass@3 36.4%.
- Set 2 has the best strict pass@1. Sets 1 and 2 tie on strict pass@3; Set 1 has the best functional pass@3. These comparisons are descriptive because 33 circuit manifests are still `imported_unverified` and the open-source structural stage is calibrated as review evidence, not a formal CDC-clean proof.
- Confirmed the checked-in Prompt Set 2 files are long and add an explicit CDC requirement, but remain visibly labeled/checklist-structured. Reports preserve the immutable `cdc_explicit` repository key instead of silently describing the actual files as unstructured.

### Phase 1 files created or modified

- Created `scripts/AK_run_codev_r1.sbatch`.
- Created `scripts/AK_eval_codev_r1_open.py`.
- Created `scripts/AK_report_codev_r1.py`.
- Created and updated `reports/AK_codev_r1_phase1_results.md`.
- Archived `reports/AK_codev_r1_preliminary_8192_truncated_18734015.md`.
- Updated the supervisor overview `reports/AK_codev1_benchmark.md` from an unrun protocol to the measured Phase 1 state.
- Created and maintained this `AK_progress.md` log.
- Created raw final artifacts under `experiments/codev-r1-rl-qwen-7b/` and preserved the excluded short-budget artifacts under `experiments/codev-r1-rl-qwen-7b-8192-truncated-18734015/`.

### Required halt

Phase 1 benchmark execution is complete. No Phase 2 debug simulation or failure-root-cause classification has been started. Await explicit user acknowledgment/approval before proceeding.

### 2026-09-29: Phase 1 release-readiness clarification

- Re-inspected the checked-in canonical testbenches without starting Phase 2. The September report describes `enhanced_cdc_tb/`, `cdc_tb_checks/lint_cdc.py`, and typed `CDC/RESET VIOLATION [RULE_ID]` / `PROTOCOL VIOLATION [RULE_ID]` output, but those artifacts are absent from this clone.
- Only three actively used canonical testbench modules (`apbxclk_tb_assert.v`, `axixclk_tb_assert.v`, and `wbxclk_tb_assert.v`) emit generic `ASSERT FAIL` protocol messages. No current canonical testbench emits the September standardized CDC rule-ID format across all 44 circuits.
- The Phase 1 evaluator did not add or modify a testbench/SVA. It added a separate supervisor-owned heuristic source checker with `AK_CDC_DIRECT_REG_CROSSING` and `AK_CDC_MULTI_DOMAIN_DRIVER` rule IDs plus SDC-context validation. This is not a replacement for the missing common-issue assertion/lint suite.
- Current automatically attributed review evidence by prompt is: `functional` 13 attempts (12 structural-heuristic attempts plus one dynamic generic protocol assertion), `cdc_explicit` 14 structural-heuristic attempts, and `observable` 13 structural-heuristic attempts. The structural finding totals are 34, 34, and 35 respectively. These are not adjudicated CDC-failure counts.
- `strict_pass` is an end-to-end composite, not the CDC-failure count: a strict failure can result from generation truncation, compilation failure, functional mismatch, timeout, tool incompatibility, SDC-context failure, or heuristic structural finding.
- Of 214 compiled attempts, 121 passed simulation and 93 did not. Raw logs contain a concrete mismatch/assertion message in 48 of the 93 nonpasses. Another 24 contain only a testbench-reported timeout and 21 are evaluator/process timeouts. Four of the 48 detailed-message logs also contain a testbench timeout.
- Identified a Phase 1 reporting limitation: 28 testbench-emitted `TIMEOUT` outcomes are currently included in the `functional_protocol_failure` primary bucket because only evaluator/process timeout is stored as `simulation_timeout`. The raw logs preserve the distinction, but a release-ready evaluator should normalize rule ID, failure message, and testbench-timeout fields into `results.json` and report multi-label evidence separately from primary status.
- Clarified denominator semantics: `40/88`, `41/95`, and `40/95` are conditional functional pass counts among successfully extracted RTL; extraction yield differs because 44, 37, and 37 attempts respectively exhausted the generation limit. Functional pass@1 uses the full 132 planned attempts per prompt. Strict pass is also reported end-to-end over 132 planned attempts.

### 2026-09-29: public-release blocker and remediation plan documented

- Created `reports/AK_PUBLIC_CDC_RELEASE_GAP_AND_PLAN.md` and marked the missing typed CDC suite as a release blocker. The document defines the supported public claim as an open-source first-pass screen for published rules, explicitly not CDC signoff or proof of metastability safety.
- Defined ten proposed stable rule families: raw scalar control crossing, synchronizer-chain integrity, multi-bit coherency, reconvergence, pulse/event crossing, request/acknowledge handshake, asynchronous FIFO, bundled-data hold, reset-domain crossing, and clock/constraint coverage.
- For every rule family, documented the required elaborated-netlist structural check, portable dynamic monitor, typed evidence, and representative mutation. The plan uses Icarus or Verilator for the required simulation path and Yosys JSON for the structural connectivity graph; SBY is optional rather than required because multi-clock property support has public limitations.
- Documented required manifest extensions: named clock/reset domains, declared crossing architecture, signal lists, applicable rules, and justified not-applicable rules. This prevents silently treating an untested rule as a pass.
- Documented a normalized per-attempt schema separating compile, functional, dynamic CDC, structural CDC, constraint checks, process timeout, and testbench timeout. The future metric is named `first_pass_screen_pass`; strict failure must never be used as a synonym for CDC failure.
- Defined release acceptance gates: every rule has positive mutants and safe controls; required mutants are detected with the expected ID; every golden circuit passes applicable checks or has a published narrow exclusion; all failures are typed; exact seeds/tool versions reproduce results; and the public runner executes all stages through one command.
- Recorded that “ten rules cover 90% of first-review findings” is currently a target hypothesis, not a supported statistic. It requires a labeled historical/engineer-created defect set and reported sensitivity before publication.
- Updated `reports/AK_codev1_benchmark.md`, `reports/AK_codev_r1_phase1_results.md` (through `scripts/AK_report_codev_r1.py`), `reports/CDC_LLM_BENCHMARK_REPORT.md`, and `reports/README.md` so readers encounter the blocker and remediation link from the existing result entry points.
- No Phase 2 candidate-level failure interpretation was started. The recommended order is to recover or rebuild the missing enhanced assets, freeze rule IDs/contracts, validate with mutations and goldens, rescore preserved candidates, and only then classify model failures.
