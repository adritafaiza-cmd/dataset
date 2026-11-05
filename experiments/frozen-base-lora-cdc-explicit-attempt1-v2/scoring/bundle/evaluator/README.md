# CDC-clean benchmark v2

The full 44-reference benchmark is retained. See [REPORT.md](REPORT.md),
[VALIDATION.csv](VALIDATION.csv), and [VALIDATION.json](VALIDATION.json).

This isolated tree includes the revised RTL, specifications, all three prompt
profiles, fixed evaluation assets, and formal contracts. It has 22 asynchronous
references, two related-clock references, and 20 single-clock controls.

All six gates pass for all 44: compile, functional TB, bounded formal assertions
and cover reachability, structural lint, enhanced TB, and Jasper structural
CDC/RDC. The three handshake primitives also pass Jasper at WIDTH=8. Deliberate
fault controls verify rejection of a synchronizer bypass and payload corruption.
Formal depths and checker/source hashes are recorded in the validation files.

The earlier base/LoRA comparison remains a v1 experiment. The original files
are unchanged and archived at ../cdc-clean-v1-frozen.tar.gz. Use fresh matched
base and LoRA generations from the v2 prompts before reporting v2 model scores.
Do not feed golden RTL or Jasper reports to the models.

Run the validation commands in REPORT.md from the original repository root.
The revision is local and has not been committed or pushed.
