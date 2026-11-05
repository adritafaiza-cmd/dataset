Fresh base versus audited LoRA comparison — v2

Generation complete: base 44/44; LoRA 44/44. All 44 paired requests are byte-identical; prompt, configuration, completion-artifact and candidate hashes verified. All 16 Slurm workers completed with exit code 0. No generation failures or missing candidates.

Token-limit terminations (8192 tokens; retained without editing or retry):
- Base: afifo, apbxclk, cdc_reset_ctrlr, wbxclk.
- LoRA: axis_switch, cdc_4phase.
These outputs may be truncated; correctness has not been scored.

All 44 cdc_explicit prompts are exact, unedited specification-only blobs from commit 1720644e81eda958b8e3dc8b55fdbb16a5415ce0, attempt 1 / seed 1. The user authorized the local commit snapshot after ecs05 SSH timed out. The missing revision markers in apb_regs and cdc_reset_ctrlr remain unchanged and are recorded in preflight.json; both prompts match the validated v2 tree.

Both arms use Qwen3.8-27B revision 1d4bf0f2ff6012fd82039f2fa52739d0dd7c60c0, BF16, SDPA, deterministic algorithms, and the pinned tokenizer template with thinking disabled. Sampling: temperature 0.2, top_p 0.95, top_k 0, max_new_tokens 8192, one beam and one returned sequence, repetition penalty 1.0. Each circuit uses seed 1 in both arms.

LoRA uses the frozen copy of training/cdc-lora-v1/retrain-audited/adapter. Weight SHA256: 52b14086b06046412f73fc60329896096931ae935eed619cc6022591f36cefa4. Adapter activation is verified in each LoRA worker environment record. manifest.json records adapter config, prompts, model support files, generator and launch settings; model-weights-sha256.json covers all 18 base model shards. candidate-inventory.csv records candidate and request hashes and termination reasons. Each attempt retains prompt.md, request.txt, response.txt, token IDs, extracted candidate, metadata, and completion hashes.

Input RTL: none. Reference RTL, exam goldens, Jasper feedback and archive/v1-broken-20 are excluded from generation inputs.

Scoring pending: ecs05 tools unavailable. No repair started. The previous scored v1 experiment on ecs05 is untouched.

Recheck artifacts with: python3 experiments/frozen-base-lora-cdc-explicit-attempt1-v2/verify.py
