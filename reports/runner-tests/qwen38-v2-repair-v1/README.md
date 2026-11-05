# Qwen3.8 v2 repair runner preparation

Implemented, without launching real repairs or model inference. These are runner tests, not experiment scores.

- 34 simulated tests pass, including service-level stub outcomes, earliest-stage ordering, restart after compile regression, all-pass early stop, three repairs total, infrastructure stops/retries, protocol separation, artifact transfer checks and interruption/resume without repeating completed inference.
- Static port-interface compatibility: 44/44 references; this is not simulation/golden checker validation.
- Base and LoRA plan-only commands each verified all 44 saved inputs. Initial candidates and sealed scoring archive remain unchanged; see preservation.json.
- Real checker access retry: ecs05.poly.edu port 22 still times out (SSH exit 255). Real Xcelium/license/GPU validation remains pending. No real repair output directory exists.

The runner is scripts/run_qwen38_repair.py. The pipeline is ports → compile → functional TB → structural lint → enhanced TB. It uses only the original specification, current candidate and one short earliest design diagnostic as model inputs. Three repairs means four candidates including the saved initial output. Jasper remains a separate final grader.

Deployment instructions and exact future commands are in scripts/README-qwen38-repair.md. repair-tools.tar.gz contains the new tools, documentation and tests, with source-sha256.json and an adjacent archive checksum. Extract it into a separate tools directory on ecs05; do not overlay the sealed scorer or dirty dataset checkout. Fresh matching golden controls must be sealed before a real endpoint can authorize design feedback.

unittest.log and test-summary.json describe simulated tests only. port-parser-compatibility.json contains static frontend compatibility, and prior frontend diagnostics are retained separately. The existing v2 compile/functional/enhanced/Jasper scoring status remains pending; these runner tests do not change any comparison score.
