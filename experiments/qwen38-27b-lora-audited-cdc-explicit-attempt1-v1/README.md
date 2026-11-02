# Frozen base versus audited LoRA comparison

Slice: all 44 circuits, cdc_explicit, attempt 1 (seed 1).
Base candidates reused from ../qwen38-27b-3prompt-10attempt-v1.
All 44 base completion hashes and shared generation identity fields were verified before submission.
The comparison-manifest.json records each base candidate and planned LoRA identity.

Adapter: training/cdc-lora-v1/retrain-audited/adapter, 318843352 bytes.
Training provenance supplied by user: job 21605634, 37 examples.
Adapter weights SHA256: 52b14086b06046412f73fc60329896096931ae935eed619cc6022591f36cefa4.
Adapter config SHA256 is also included in candidate identities.

Only existing frozen experiments/prompts/*.cdc_explicit.md files are model inputs.
The pinned base tokenizer applies enable_thinking=False. No exam goldens or Jasper feedback are loaded.
Generation settings, revision, BF16 precision, seed and prompt hashes match existing base metadata.
No training, repair or scoring is part of this run. Scoring on ecs05 follows separately.

The requested reports/progress-track/MODELING_FOR_CODEX_2026-11-01.md was absent from this checkout.
Execution follows the explicit user instructions and verified base metadata.

Syntax validation passed; initial dry run: 44 attempts, 0 completed, 44 pending.
Smoke job: 21628400. See generate-21628400.log.

Progress / completion validation:
```bash
.cache/qwen38-venv/bin/python scripts/generate_qwen38_27b_3prompt.py --output experiments/qwen38-27b-lora-audited-cdc-explicit-attempt1-v1 --attempts 1 --prompt-types cdc_explicit --adapter training/cdc-lora-v1/retrain-audited/adapter --dry-run
```

Smoke PASSED: Slurm COMPLETED, exit 0:0; 1732 tokens in 159.17 seconds.
Adapter active across 256 layers; completion hashes verified; request.txt byte-identical to base.
Remaining generation submitted as job 21629523, skipping the completed smoke candidate (43 pending).
Log: generate-21629523.log.

```bash
squeue -j 21629523
tail -f experiments/qwen38-27b-lora-audited-cdc-explicit-attempt1-v1/generate-21629523.log
cat experiments/qwen38-27b-lora-audited-cdc-explicit-attempt1-v1/progress-rank-0.json
```
