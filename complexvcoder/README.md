# ComplexVCoder (27 of 264)

LLM-generated RTL from a paper-style ComplexVCoder / SysVCoder pipeline
(English → GIR → Verilog), scored on NYU Tandon ecs05.

| | |
|---|---|
| Generated | Torch HPC, 13 Sep 2026, NVIDIA H200 |
| Model | `Qwen/Qwen2.5-Coder-7B-Instruct` (not the paper 32B) |
| Official code | no (`official_implementation: false`) |
| Zip | `complexvcoder-20260913T034714Z-27-of-264.zip` |

This folder is **generated RTL only**. It does not contain golden / fixed
benchmark sources.

## Score (13 Sep 2026, ecs05)

| Gate | Result | Tool |
|---|---|---|
| Compile | **8 / 27** | Xcelium |
| Functional | **0 / 27** | Xcelium (`ALL TESTS PASSED` required) |
| CDC | **0 / 27** | JasperGold **never started** |

Jasper runs only after a functional pass. Every `cdc_errors` field in
`all_generated_eval_summary.json` is `null`.

| Circuit | Attempts | Compile | Functional | CDC |
|---|---|---|---|---|
| afifo | 6 | 4 | 0 (TESTS FAILED / TIMEOUT) | not run |
| apb_cdc | 6 | 1 | 0 (TESTS FAILED) | not run |
| apb_regs | 6 | 0 | — | — |
| apbslave | 6 | 3 | 0 (TESTS FAILED / TIMEOUT) | not run |
| apbxclk | 3 | 0 | — | — |

`cdc_explicit` prompts did not help. Full write-up:
[EVAL_REPORT.md](EVAL_REPORT.md). Machine-readable scores:
[all_generated_eval_summary.json](all_generated_eval_summary.json).

## Layout

```
complexvcoder/<circuit>/<functional|cdc_explicit>/attempt-00N/
  prompt.md
  gir.txt                 # intermediate representation
  generated/<circuit>.v   # RTL that was scored
  metadata.json
  results.json            # compile / sim / cdc fields
  complete.json
```

## What is not here

- Golden RTL (`benchmarks/*/fixed/rtl`) — that is a different zip
  (`dataset-torch.tar`). That tree **was** fully scored: 44/44 functional
  and 44/44 Jasper reports.
- The other 237 ComplexVCoder attempts (zip is 27 of 264).

## Re-score on ecs05

```tcsh
setenv PATH /eda/cadence/XCELIUM2603/tools.lnx86/inca/bin/64bit:/eda/cadence/JASPER/bin:$PATH
setenv DS /home/ft2335/dataset
cd /home/ft2335/dataset
python3 scripts/eval_all_generated.py --model-dir experiments/complexvcoder
```
