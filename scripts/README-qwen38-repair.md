# Qwen3.8 v2 repair runner — implemented, not launched

This runner starts with the **saved v2 initial candidate**, followed by at most **three repairs** (four candidates total). No initial generation is repeated. The base arm uses Qwen3.8-27B BF16 without an adapter; LoRA uses the exact frozen audited adapter under the v2 experiment. Model revision, settings and adapter hashes come from that experiment's manifest. Repair n uses seed 1+n in both arms, with the same sampling settings as initial generation. Requests use the pinned tokenizer's template with thinking disabled; context overflow stops generation instead of truncating inputs.

The sealed scoring bundle and all 88 initial candidates are inputs only. Outputs must be outside that experiment. Nothing in this implementation invokes `scripts/run_qwen25_repair.py`.

## Current verification

`reports/runner-tests/qwen38-v2-repair-v1/` contains **runner tests, not experiment results**. Simulated checker outcomes test order, earliest-stage feedback, stop conditions, three repairs, compile regression, infrastructure handling, protocol separation, transfer integrity and resume after durable inference. Static interface compatibility checks use the 44 reference interfaces without running model repairs or simulations. These tests do not establish Xcelium/Jasper license or checker validity. Real checker integration and GPU inference remain unexercised until access returns.

## Plan without executing

```bash
python3 scripts/run_qwen38_repair.py --arm base
python3 scripts/run_qwen38_repair.py --arm lora
python3 -m unittest discover -s scripts -p test_qwen38_repair.py -v
```

The default commands verify and list all 44 inputs per arm, then exit. They do not instantiate a model, check a candidate, or create a real repair experiment. `--circuits` selects a subset for a later controlled launch. `--max-repairs` is bounded to 0..3. `--execute` is deliberately absent from preparation/testing.

## Checker preparation after ecs05 access returns

1. Extract the preserved scoring bundle into a **new** ecs05 directory. Verify its archive checksum and `bundle/verify_bundle.py`. Do not overlay the dirty dataset checkout.
2. Use its scoring entry point to establish fresh golden controls with the real license environment. Keep all golden records and native logs. This is grading/checker validation, not a repair launch.
3. Deploy the new `scripts/cdc_repair/` package to a separate tools directory. No modification to the sealed bundle is needed.
4. Bind the controls to the exact evaluation-asset manifest:

```bash
PYTHONPATH=/home/ft2335/repair-tools/scripts python3 -m cdc_repair.seal_controls \
  --bundle /home/ft2335/score-v2/bundle \
  --golden-results /home/ft2335/score-v2/bundle/evaluator/experiments/frozen-v2-scoring/golden \
  --output /home/ft2335/score-v2/fresh-golden-controls.json
```

The command reports the control SHA256. It verifies all evaluation source hashes, all 44 golden record identities and reference hashes. Non-pass golden stages remain recorded; they block the corresponding repair check rather than becoming candidate feedback. Do not construct a real attestation from simulated results.

5. Create a checker-command JSON argv on HPC using these example paths adjusted to the isolated extraction:

```json
[
  "ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=15", "ecs05.poly.edu",
  "env PYTHONPATH=/home/ft2335/repair-tools/scripts python3 -m cdc_repair.checker --assets /home/ft2335/score-v2/bundle/evaluator --manifest /home/ft2335/score-v2/bundle/evaluation-asset-hashes.json --workspace /home/ft2335/repair-check-work-v1 --controls /home/ft2335/score-v2/fresh-golden-controls.json"
]
```

The same JSON protocol also supports a local checker argv. SSH must run in a shell environment with working Xcelium licensing; missing tools/licenses stop the chain. Each request carries the exact candidate text/hash and expected asset/control hashes. The checker copies verified assets into its own workspace and writes native work products there; it does not write into the sealed evaluator. Response artifacts carry base64-encoded exact bytes and SHA256, with safe relative paths.

Before a later authorized model launch, smoke-test this endpoint against real golden/control cases, compile failure, functional failure and lint failure. Use short stdin JSON requests with `schema_version`, `circuit`, `candidate`, `candidate_sha256`, `evaluation_manifest_sha256`, `controls_sha256`. A ready endpoint returns JSON on stdout; stderr is preserved independently. A transport, tool, license or timeout failure never triggers model repair.

A future execution command adds `--execute --checker-command-json <argv.json> --checker-controls-sha256 <reported-sha256>` to the HPC runner invocation. It requires exactly one visible allocated NVIDIA GPU and the existing `.cache/qwen38-venv/bin/python` environment. **No such execution has been launched.** Resume uses the same command, output directory, code and input/control identities; changes cause a resume error rather than silently mixing experiments.

## Check and feedback contract

Every candidate starts at **ports → compile → functional TB → structural lint → enhanced TB**. Stop at the earliest failed or unavailable stage; later stages are explicitly `not_run`. Restart at ports after every repair. Stage status and runtime, native commands, stdout/stderr, generated shell/Tcl scripts and all tool log files are preserved.

The ports frontend checks module identity, port names and directions in ANSI/non-ANSI headers. It handles include guards, ordinary conditional compilation and header includes with the canonical include paths/defines; it does not claim width equivalence or full preprocessing. Symbolic widths and elaboration remain the compile/TB harness's responsibility. Unsupported frontend syntax is `inconclusive`/`checker_invalid`, not a guessed design failure. Golden top interfaces supply the expected port contract **only inside the checker**.

Compile, functional, lint and enhanced checks use the frozen validated v2 helper implementations and the same fixed dependency harness as scoring. Embedded lint is disabled in simulation (`CDC_CHECKS=0`) so functional results stay separate from structural lint. The canonical lint scope is the selected top file. Fresh matching golden controls gate each real checker stage. Protocol violations and CDC/reset evidence from enhanced TBs are saved in separate fields.

Only `design_failure` can trigger repair. The model-facing diagnostic is one bounded, whitelisted message from the earliest failing stage, at most 1000 characters. The model prompt contains exactly the original specification, current candidate and that diagnostic, plus the request to return replacement RTL. Full native logs, checker metadata, golden RTL, dependency sources, goldens and Jasper output never enter model prompts.

`tool_unavailable`, `missing_assets`, `license_failure`, `timeout`, `tool_error`, `transport_error`, `checker_invalid`, `inconclusive`, and `generation_error` are infrastructure/inconclusive outcomes. They stop the current run for retry without consuming another repair generation. Historical failed infrastructure attempts are retained; a retry reruns checks on the same candidate. A missing generated include is currently classified conservatively as missing_assets, not automatically repaired from tool output.

**Jasper is a final grader only.** The repair checker does not import or invoke the Jasper wrapper, and the model prompt has no Jasper field. Runner success means the five repair checks passed; it does not assert a Jasper pass. Preserve final candidate paths/hashes for later independent Jasper grading of both arms.

## Artifact and resume contract

Default future output: `experiments/qwen38-v2-repair-v1/<arm>/<circuit>/`.

- `identity.json`: original candidate/spec, arm, frozen model/adapter identity, checker/control hashes, code hashes and maximum repairs.
- `candidate-000/`: exact initial RTL, original spec, source/truncation metadata; no generation occurs.
- `candidate-001/` through `candidate-003/`: exact user prompt, feedback input, replacement candidate, generation metadata and immutable completion hashes.
- `model-generation/`: exact chat request, raw response text/token IDs, extraction result, tokenizer/generation settings, adapter activation, hardware/software metadata and original inference runtime. Only Markdown fence wrappers and terminal model EOS are removed using the same extraction convention as the initial generation.
- `inference-complete.json`: a durable receipt allows finalization after interruption without reloading/rerunning the model. `complete.json` commits finalized model artifacts; `candidate-complete.json` commits the outer candidate transaction.
- `checks/attempt-NNNN/`: exact checker request/response, command, transport runtime, native artifacts and stage result/hashes. Completed pass/design-failure checks are reused; infrastructure retries create a new attempt.
- `feedback.txt`: the earliest design diagnostic; the next candidate retains identical `feedback_input.txt` bytes.
- `status.json`: current candidate hash, repairs completed, terminal/infrastructure status and Jasper pending status.

All resume reads reverify artifact hashes and input identities. Per-circuit locks prevent concurrent mutation. The runner does not normalize or overwrite saved candidates, discard truncation cases, or treat runner tests as benchmark scores.
