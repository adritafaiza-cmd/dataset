# Multi-LLM Pass@k experiment

This experiment compares API-accessible LLMs under one frozen prompt and one
identical evaluation pipeline. It is separate from:

- the fixed 18-attempt one-shot baselines;
- `rtlcoder-deepseek-until-functional-pass/`;
- feedback/repair agents.

## Protocol

For each model and attempt:

1. Send the unchanged prompt through OpenRouter (no compiler or simulation
   feedback).
2. Preserve the request, raw response, extracted RTL, metadata, and failures.
3. Compile/elaborate with Xcelium and the existing repository testbench.
4. Run the existing functional simulation with a 50 us cap.
5. Only after functional pass, run JasperGold with the benchmark's existing
   SDC, clocks, resets, and CDC/RDC setup.

The script accepts 1–10 attempts per model. Repeat `--model` to compare several
models. OpenRouter receives the same attempt seed across models. GPT-5.6 on
OpenAI's Responses API does not accept temperature, top-p, or seed, so those
runs use the provider defaults and record that limitation. Model outputs are
never edited.

## Run on ecs05

### Direct OpenAI — GPT-5.6 Sol

Set the existing OpenAI API key in the shell without writing it to a file:

```tcsh
setenv OPENAI_API_KEY 'your-key'
```

Run Sol directly through the OpenAI Responses API:

```tcsh
cd /home/ft2335/dataset
python3 scripts/run_multi_llm_passk.py \
  --provider openai \
  --model gpt-5.6-sol \
  --circuit cdc_2phase \
  --prompt-type cdc_explicit \
  --attempts 10
```

The `gpt-5.6` alias also routes to Sol, but the explicit
`gpt-5.6-sol` identifier makes experiment provenance clearer.

### OpenRouter models

Set the OpenRouter key:

```tcsh
setenv OPENROUTER_API_KEY 'your-key'
```

Then select currently available OpenRouter model IDs:

```tcsh
cd /home/ft2335/dataset
python3 scripts/run_multi_llm_passk.py \
  --provider openrouter \
  --model '<provider/model-a>' \
  --model '<provider/model-b>' \
  --circuit cdc_2phase \
  --prompt-type cdc_explicit \
  --attempts 10
```

Run functional and CDC-explicit prompts as separate experiments. Do not merge
their success counts.

The runner is resumable. Existing evaluated attempts are skipped. An
incomplete attempt is renamed with an `.incomplete-<timestamp>` suffix before
that attempt number is generated again.

## Pass@k

For `n` evaluated samples and `c` successes, the report uses the standard
unbiased estimator:

```text
pass@k = 1 - C(n-c, k) / C(n, k)
```

It records separate curves for:

- compile success;
- functional success;
- functional **and** Jasper CDC/RDC-clean success.

The JSON also records observed prefix success, which answers whether one of the
first `k` generated attempts passed. This is not substituted for the standard
Pass@k estimator.

Results are written beneath:

```text
experiments/multi-llm-passk/
  <api-provider>/protocol.json
  <api-provider>/<model>/<circuit>/<prompt>/attempt-NNN/
  <api-provider>/<circuit>.<prompt>.pass_at_k_summary.json
```
