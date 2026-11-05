# Frozen base versus LoRA v2: partial scoring and ecs05 handoff

Dynamic scoring is blocked. HPC has no Xcelium/Jasper (or Icarus) executable; SSH to ecs05.poly.edu times out on port 22 (exit 255). This is infrastructure unavailability, not a candidate design failure. No license check could be performed.

All 44 circuits remain in each arm denominator. All 88 saved candidates are unchanged and hash-verified. The six token-limit outputs remain included, flagged, and unedited: base afifo, apbxclk, cdc_reset_ctrlr, wbxclk; LoRA axis_switch, cdc_4phase.

## Verified evaluation inputs

The evaluation source is benchmark-revisions/cdc-clean-v2/ at exact commit 1720644e81eda958b8e3dc8b55fdbb16a5415ce0. All 666 selected files match direct Git object contents, with commit path, Git blob SHA1 and content SHA256 recorded in bundle/evaluation-asset-hashes.json. This includes the reference RTL, fixed helper RTL, canonical/enhanced TBs, manifests, vendor/header dependencies, constraints, Jasper setup and checker code. Static simulation/manifest/include reference checks found no missing assets. A separate Jasper dependency audit is recorded.

The commit live paths differ from the isolated validated tree. The rejected live-path audit is preserved under live-tree-preflight-rejected/; it is not used for the v2 results below. No prompt or candidate was altered to resolve the evaluator mismatch. The generation commit and authorized marker discrepancy remain recorded in generation-preflight.json.

## Golden controls and scope

Canonical structural lint controls: 44/44 pass. The pinned v2 validator lints only the selected golden top; the same scope is used for candidate lint. This is a heuristic text checker, not full-design CDC signoff. A supplemental scan of complete golden helper source lists reports patterns in async_bidir_fifo, async_bidir_ramif_fifo and async_fifo; raw logs are preserved under supplemental-full-source-lint/. Those broader probes do not replace the pinned validator scope.

The typed-evidence source audit passes for all 44 enhanced testbenches. This checks message classification only; it is not a behavioral test. Fresh compile, functional, enhanced and Jasper golden controls could not run. Historical VALIDATION.* evidence is included for provenance and is not claimed as fresh checker validation.

## Current results

| Check | Base, denominator 44 | LoRA, denominator 44 | Golden controls |
|---|---|---|---|
| Compile | 44 tool unavailable | 44 tool unavailable | Not run |
| Functional TB | 44 tool unavailable | 44 tool unavailable | Not run |
| Structural lint | 38 pass; 6 rule failures | 34 pass; 10 rule failures | 44 pass |
| Enhanced behavioral TB | 44 tool unavailable | 44 tool unavailable | Not run |
| Jasper structural CDC/RDC | 44 tool unavailable | 44 tool unavailable | Not run |
| All five pass | Pending | Pending | Dynamic controls pending |

No all-five pass is established. Lint failures already preclude all-five success for 6 base and 10 LoRA candidates; the remaining candidates still need all dynamic checks. Protocol results are separate: enhanced protocol evidence is not_run and Jasper protocol is not_run. The planned Jasper mode is fixed structural CDC/RDC, not protocol proof or metastability/MTBF signoff.

Per-circuit lint gains (base rule failure to LoRA pass): afifo, apbxclk, cdc_reset_ctrlr, isochronous_spill_register.

Per-circuit lint losses (base pass to LoRA rule failure): apb_regs, async_bidir_ramif_fifo, async_fifo_sv, axis_adapter, axis_async_fifo, axis_async_fifo_adapter, axis_register, axixclk.

All dynamic-stage gains/losses remain pending. No tool absence, failed control, license error or timeout is converted into a model loss. paired-results.csv has all 44 paired rows, stage statuses, hashes, truncation flags and per-stage gains/losses.

## Handoff artifacts

- scoring-bundle.tar.gz and scoring-bundle.tar.gz.sha256: sealed, relocatable scoring inputs, candidate copies, local results, report and instructions.
- RUNBOOK.md: extract into a new directory on ecs05; do not merge into its dirty checkout.
- bundle/score_on_ecs05.py: checksum-verifies inputs, requires Xcelium/Jasper, runs 44 fresh golden controls first, and then scores both arms independently without candidate normalization. Its Python syntax and hash-checking dry run passed; dynamic execution is untested due unavailable tools.
- bundle/candidate-hashes.json: all 88 exact candidate hashes, completion provenance and termination flags.
- results/: per-circuit golden/candidate lint findings and full stdout/stderr, tool preflight, source-reference audit, typed-evidence logs and machine-readable summaries.
- paired-results.csv: current paired table (also under results/).
- ecs05-access.*.log and access-blocker.json: full access error and command.

The remote driver records commands, native logs, generated scripts, stage classifications, independent enhanced protocol/CDC-reset evidence and hashes before/after scoring. Golden failures gate only the corresponding circuit/stage. Inspect design_failure, missing_assets, tool_unavailable, tool_error, license_failure, timeout, constraint_mismatch and inconclusive statuses separately. All 44 remain in each denominator. The existing fixed dependency harness is shared by both arms; these are harness scores, not standalone full-design generation scores.

The previous v1 experiment is untouched. No repair, regeneration or model invocation occurred. Jasper output remains exclusively evaluation data.
