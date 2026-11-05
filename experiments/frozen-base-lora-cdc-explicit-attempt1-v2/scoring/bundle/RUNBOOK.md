Scoring handoff for ecs05

Use a new empty directory on ecs05. Do not overlay or merge into /home/ft2335/dataset. Extract scoring-bundle.tar.gz, verify the adjacent SHA256 first, then run:

```bash
python3 bundle/verify_bundle.py
python3 bundle/score_on_ecs05.py
python3 bundle/score_on_ecs05.py --execute
```

Run from the same ecs05 shell that supplies working Xcelium and Jasper licenses. The scorer adds the canonical /eda/cadence/XCELIUM2603/tools.lnx86/inca/bin/64bit and /eda/cadence/JASPER/bin paths. The dry run requires no tools and verifies 88 candidate hashes and all evaluation assets. --execute refuses to proceed unless xrun and jg are available. The dynamic scoring driver was syntax checked and dry-run checked on HPC; its dynamic execution has not been validated here.

Evaluation source is the entire isolated validated tree at commit 1720644e81eda958b8e3dc8b55fdbb16a5415ce0, rooted at benchmark-revisions/cdc-clean-v2/. The commit's live paths are not equivalent evaluation assets. See live-tree-preflight-rejected/asset-audit.json for the differences; those preliminary scores are not v2 results. Evaluator scripts, reference RTL, helper RTL, manifests, canonical/enhanced testbenches, vendor headers and Jasper constraints in bundle/evaluator are frozen. evaluation-asset-hashes.json maps every file back to its commit path and Git blob, with SHA256. Historical VALIDATION.* files are provenance, not a replacement for fresh controls.

The entry point runs all 44 goldens through compile, functional, structural lint, enhanced TB and fixed structural Jasper before either candidate arm. A failed or unavailable golden stage marks that circuit's corresponding candidate stage checker_invalid. Stages are independent; lint/functional failures do not suppress unrelated Jasper/enhanced checks after valid controls. Embedded automatic lint in simulation scripts is disabled using CDC_CHECKS=0 so structural lint and simulation are scored separately. Canonical helpers substitute only the selected top; fixed benchmark helper RTL dependencies remain the same for both arms. Canonical lint controls inspect the selected golden top and candidate lint inspects the saved candidate file, matching validate_cdc_clean_v2.py. A supplemental full-source lint probe flags protected helper-pointer patterns in three goldens; it is retained separately and does not replace the canonical gate. Lint is a top-file heuristic, not a complete dependency-graph analysis. Scores are within this shared harness, not standalone full-design scores.

All 44 circuits remain in each arm denominator. Copies of candidates retain exact bytes and .sv extensions, including malformed/truncated output. No Markdown normalization, RTL editing, regeneration, repair or model call occurs. Before and after execution all candidate/source hashes are verified. Truncation flags are carried into per-circuit rows and paired-results.csv. The generation's six token-limit cases must remain in every aggregate denominator.

Dynamic outputs are under bundle/evaluator/experiments/frozen-v2-scoring/. Full generated shell/Tcl scripts and native logs are also under bundle/evaluator/build/. Preserve both directories together with results.json, paired-results.csv, stage command records and this bundle's input hash manifests. Return these artifacts to the Torch experiment's scoring directory for the final report. Refuse to reuse an existing output tree: use a fresh extraction to retry, preserving prior logs.

Jasper runs the fixed structural CDC/RDC mode only. Its extra legacy protocol/metastability commands are disabled. Jasper protocol is explicitly not_run, not pass. Enhanced logs retain typed PROTOCOL VIOLATION and CDC/RESET VIOLATION evidence separately. A missing protocol violation on a passing test is an observation, not a protocol proof.

Statuses distinguish pass, design_failure, missing_assets, tool_unavailable, tool_error, license_failure, timeout, constraint_mismatch, inconclusive_coverage, inconclusive_no_pass_marker and checker_invalid. Inspect exact native logs before attributing a tool/constraint failure to RTL. The fixed Jasper dialect and module/dependency harness are preserved; no candidate-specific constraint edits are permitted. All-five is pass only if all five valid-control stages pass; unresolved infrastructure/checker conditions remain pending unless a design failure already establishes non-pass. Stage gains/losses require pass versus design_failure; unavailable results are never treated as losses. Protocol evidence does not silently change the fixed structural Jasper score.

The archived v1 experiment is untouched. No Jasper output goes to a model. Repairs remain prohibited.
