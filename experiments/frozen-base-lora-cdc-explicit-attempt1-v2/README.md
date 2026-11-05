Fresh frozen base versus audited LoRA comparison, v2

44 circuits, cdc_explicit, attempt 1 (seed 1). Both arms freshly generated.
Prompts are exact unedited Git blobs from 1720644e81eda958b8e3dc8b55fdbb16a5415ce0.
The user authorized this commit snapshot after ecs05 SSH timed out.
apb_regs and cdc_reset_ctrlr lack revision markers; contents match the validated v2 tree. See preflight.json.

Inputs are specification-only prompts. No reference RTL, exam goldens, Jasper feedback, or archive/v1-broken-20 files are model inputs.
The audited adapter is frozen in adapter/ and identified in manifest.json.
Both arms share prompts, seed, tokenizer/template, BF16 precision and generation settings.

Generation array: 21890142; 8 workers per arm, one H200 per worker.
Run python3 verify.py from this directory to validate coverage and hashes.
Scoring pending: ecs05 tools unavailable. Repair has not started.
The previous scored experiment on ecs05 has not been modified.

Generation finished: base 44/44; LoRA 44/44; all 44 paired requests verified. See REPORT.md and generation-report.json. No worker failures; six token-limit terminations retained. Scoring pending; no repair.
