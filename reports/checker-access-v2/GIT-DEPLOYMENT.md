# Git handoff: isolated ecs05 worktree

Branch: `codex/frozen-base-lora-v2-handoff`, based on validated commit `1720644e81eda958b8e3dc8b55fdbb16a5415ce0`. This branch adds the frozen 88 candidates, exact prompts/requests/responses, provenance, partial scoring, sealed evaluator bundle, and the repair runner. It does not merge or modify prior experiments.

From the existing ecs05 repository (do not checkout/reset/merge its dirty working tree):

```bash
git fetch origin refs/heads/codex/frozen-base-lora-v2-handoff:refs/remotes/origin/codex/frozen-base-lora-v2-handoff
git worktree add --detach /home/ft2335/dataset-v2-scoring origin/codex/frozen-base-lora-v2-handoff
cd /home/ft2335/dataset-v2-scoring
python3 experiments/frozen-base-lora-cdc-explicit-attempt1-v2/scoring/bundle/verify_bundle.py
```

Verify the SHA256 of `scoring/scoring-bundle.tar.gz` against its adjacent checksum before extracting to another fresh directory if needed. Use `bundle/evaluator/`, the exact validated isolated v2 tree, not the repo's mixed live paths or rejected preflight assets. `bundle/score_on_ecs05.py` is dry-run by default; `--execute` requires xrun/jg and writes new isolated work products only. Its dynamic execution is still awaiting real tool validation.

Read `HANDOFF.md`, the scoring `RUNBOOK.md`, and `scripts/README-qwen38-repair.md`. The continuation order is fresh real golden controls → initial scoring of all 88 unchanged candidates → counted real integration repairs across different earliest failures → full repair continuation → final Jasper and paired report. Preserve the candidate denominator 44 per arm and all six initial token-limit flags. Protocol outcomes and infrastructure failures stay separate. Do not tune feedback from Jasper.

The integration subset and full repairs must share the same output directory and max-repairs=3 identity. Every real integration generation counts toward the three-repair maximum. Do not restart chains or repeat completed inference when broadening the subset.

No model or adapter weights are in Git, including the intentionally absent `adapter/adapter_model.safetensors`. Manifests and the small adapter config identify the exact retained weights. On Torch use the existing original experiment at `/scratch/ft2335/dataset-observable/experiments/frozen-base-lora-cdc-explicit-attempt1-v2` via `--experiment` so the runner can verify and load its frozen local adapter. Do not try to load Qwen on ecs05. The checker endpoint runs on ecs05; GPU generations run on Torch using the documented JSON/SSH exchange or a supported restored route.

Local SSH configuration, managed/pinned host-key files, credentials, and revoked email material are excluded. Connection details mentioned in the historical handoff may refer to local-only diagnostics. No support email should be recreated or resent. Unrelated email metadata was removed from the published continuation copy only; frozen experiment identities were not changed.

`git-payload-manifest.json` records copied artifact hashes and exclusions. `ECS05-CODEX-MESSAGE.md` contains the handoff message. The original HPC workspace, dirty changes, original candidates, and sealed archive remain untouched.
