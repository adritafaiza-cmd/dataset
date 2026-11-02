# Adapter selection

The original `adapter/` and `adapter-epoch-*` checkpoints came from job 21601335, which completed successfully but trained on 10 modules rejected by the source audit. They are preserved for provenance and should not be selected for the audited experiment.

The frozen allowlist is `audit.md`: 37 keep, 28 drop (10 formerly trained plus 18 already excluded for length). `train.jsonl` contains exactly the 37 kept pairs. All 31 dev pairs remain excluded. `run-21601335/` preserves the original input and logs.

A single fresh retrain was submitted as job 21605634 using `scripts/cdc_lora_audited.sbatch`, with the same base model and hyperparameters. Its destination is `retrain-audited/adapter/`. Job 21605634 completed successfully (exit 0:0) in 5m34s; all 37 examples trained for two epochs with zero skips. This is the active audited adapter. `retrain-status.json` records the final checks and manifest/data hashes.

`python scripts/check_cdc_audit.py` verifies the manifest, source/spec hashes, training pair contents, and split exclusion. The heuristic split preparation script refuses to overwrite this manifest. No held-out evaluation has been performed here.
