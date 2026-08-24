# RTLCoder-DeepSeek Pass@20 (separate experiment)

This directory is **not** the frozen 18-attempt baseline.

| Experiment | Directory | Protocol |
|---|---|---|
| Official one-shot baseline | `experiments/rtlcoder-deepseek-v1.1/` | 3 attempts, independent, already frozen |
| This experiment | `experiments/rtlcoder-deepseek-until-functional-pass/` | Pass@20 sampling, max 20, no error feedback |

Do not unzip or copy candidates into `experiments/rtlcoder-deepseek-v1.1/`.
Do not report Pass@20 numbers in the same column as the 18-attempt compile/sim rates.

## What this is

Each attempt receives only the original frozen prompt. There is no Xcelium error feedback. That is Pass@20 sampling, not the compile-repair agent.

A later feedback-repair run would be a third experiment and a third column.

Colab cannot decide functional pass or CDC-clean. It has no Xcelium, no repository testbenches, and no JasperGold.

## Generate on Colab

Use `notebooks/rtlcoder_deepseek_pass20_colab.ipynb`, not the original 18-attempt notebook.

Download `rtlcoder-deepseek-until-functional-pass.zip`.

## Evaluate on ecs05

```tcsh
cd /home/ft2335/dataset
unzip -o rtlcoder-deepseek-until-functional-pass.zip
python3 scripts/evaluate_pass_at_n.py \
  --model-dir experiments/rtlcoder-deepseek-until-functional-pass
```

The evaluator compiles attempts in order, simulates compile-pass RTL for 50 µs, stops at the first official-testbench pass, and runs JasperGold only on that file.

## Report

| Circuit | Prompt | First compile pass | First functional pass | CDC-clean |
|---|---|---|---|---|
| cdc_2phase | functional | Attempt N | Attempt N or none | Result |
| cdc_2phase | cdc_explicit | Attempt N | Attempt N or none | Result |
| async_fifo | functional | Attempt N | Attempt N or none | Result |
| async_fifo | cdc_explicit | Attempt N | Attempt N or none | Result |
| apbxclk | functional | Attempt N | Attempt N or none | Result |
| apbxclk | cdc_explicit | Attempt N | Attempt N or none | Result |

Layout after generation:

```text
cdc_2phase/{functional,cdc_explicit}/attempt-001 ... attempt-020
async_fifo/{functional,cdc_explicit}/attempt-001 ... attempt-020
apbxclk/{functional,cdc_explicit}/attempt-001 ... attempt-020
```
