# CDC clean v2 generated RTL

This snapshot contains 3,120 generated RTL candidates with their original prompts,
responses, metadata, and completion manifests. Every artifact listed in each
completion manifest was checked against its recorded SHA-256 before committing.
Completion records generation output, not compilation or functional correctness.

| Run directory | Circuits | Prompt types | Attempts per prompt | RTL candidates |
| --- | ---: | ---: | ---: | ---: |
| `cdc-clean-v2-qwen25-coder-32b-3x10` | 20 | 3 | 10 | 600 |
| `cdc-clean-v2-qwen38-27b-3x10` | 20 | 3 | 10 | 600 |
| `cdc-clean-v2-rtlcoder-deepseek-3x10` | 20 | 3 | 10 | 600 |
| `cdc-clean-v2-complexvcoder-32b-all44` | 44 | 3 | 10 | 1,320 |

Prompt types are `functional`, `observable`, and `cdc_explicit`. The three
20-circuit runs use the circuit list in `scripts/cdc_clean_v2_fixed20.txt`.
Qwen 3.8 outputs were copied byte for byte from the external generation directory.
Only the selected completed attempts are included; scratch files and interrupted
attempts are excluded.

ComplexVCoder is the paper reimplementation recorded in its manifests, using
Qwen2.5-Coder-32B-Instruct, without GIR finetuning or retrieval. Its manifests
identify it as an unofficial implementation. Model revisions, sampling settings,
and generation script hashes are preserved in the per-attempt provenance.
