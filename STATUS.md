# CDC-Aware RTL Generation: project status

**Researcher:** Faiza  
**Meeting:** Monday (advisor)  
**Date:** 22 August 2026  
**Repo:** https://github.com/adritafaiza-cmd/dataset

---

## What the project is about

The goal is a **fair benchmark for LLM-generated RTL that must be both functionally correct and CDC/RDC-safe**.

Existing RTL-generation work mostly scores compile and simulation. That misses a common hardware failure mode: a design can compile, even pass a testbench, and still have **unsafe clock-domain or reset-domain crossings**. Those bugs are silent in 0-delay simulation and show up in silicon or in CDC tools such as JasperGold.

The experiment is:

1. Collect and verify CDC circuits (target ~100–150; **11 are the current pilot**).
2. Turn each into a generation spec/prompt that does **not** leak the reference RTL.
3. Ask several model classes to generate the same module (same ports, same tests, same Jasper settings).
4. Score every attempt on compile, functional sim, CDC/RDC, assertions, and later synthesis.
5. Report pass rates over multiple attempts. Keep failures.

**Novelty to defend:** models (and naive RTL) can look correct under simulation while JasperGold still reports CDC/RDC errors. We do **not** claim “models cannot detect CDC” until that is measured.

---

## What we have built

### 1. Pilot benchmark (11 circuits)

Families:

- **dpretet:** `async_fifo`, `async_bidir_fifo`, `async_bidir_ramif_fifo`
- **ZipCPU:** `wbxclk`, `axixclk`, `apbxclk`
- **verilog_axis:** `axis_async_fifo`, `axis_async_fifo_adapter`
- **pulp_platform:** `cdc_2phase`, `cdc_4phase`, `cdc_2phase_clearable`

Each circuit is a reproducible benchmark:

```text
benchmarks/<name>/
  original/rtl/     # snapshot before our CDC/RDC fixes
  fixed/rtl/        # verified reference (not used in prompts)
  constraints/      # SDC
  tb/
  jasper/run.tcl
  sim/run.sh
  manifest.yaml
  specification.md  # draft, not the final LLM prompt
```

Provenance:

- Baseline (pre-fix RTL + SDC/Jasper): commit `0d63dfb`
- CDC/RDC-fixed RTL + TBs: commit `a609317`
- Benchmark layout: commit `bf3672c`

The golden RTL is JasperGold CDC/RDC-clean (0 errors / 0 warnings / no undeclared clocks) and has functional Xcelium tests.

### 2. Monday pilot experiment (3 circuits)

Circuits: `cdc_2phase` (small handshake), `async_fifo` (medium FIFO), `apbxclk` (APB clock bridge).

Two prompt variants each:

- **functional** — ports and behavior only
- **cdc_explicit** — same, plus “must pass CDC/RDC with zero unsafe crossings”

Prompts do **not** mention Gray code, flop-stage counts, or the reference RTL.

### 3. Llama baseline (done)

OpenRouter does not host Llama 3.1 405B (`404 No endpoints found`). The live baseline is **Llama 3.3 70B Instruct**.

- 3 circuits × 2 prompts × 3 attempts = **18** generations
- Saved under `experiments/llama-3.3-70b-instruct/` (prompt, raw response, extracted RTL, metadata)
- Generated RTL was **not** edited

**Llama 3.3 70B results**

| Stage | Result |
|---|---|
| Compile | **4 / 18** (only some `apbxclk`) |
| Functional simulation | **0 / 18** |
| CDC-clean among analyzed compiles | **0** |

Typical compile failure: `WANOTL` (assignment to a `wire`/`output` net inside `always`).  
Typical sim failure: broken APB handshake (ack before the master transfer, `S_PREADY` never rises, `PENABLE` without `PSEL`).  
The CDC-explicit prompt did **not** fix this.

Label slides as **Llama 3.3 70B Instruct**, not 405B.

### 4. Human-repaired “func-pass / CDC-fail” examples

These are **not** Llama outputs and **not** edits to the open-source or golden RTL. They live in `experiments/human_repaired/`.

They implement the same three modules so that:

- Xcelium testbenches **pass**
- JasperGold still reports **CDC/RDC errors**

No Gray pointers, no 2-flop synchronizers, no reset synchronizers.

| Design | Sim | JasperGold |
|---|---|---|
| `cdc_2phase` | ALL TESTS PASSED | 2 RDC errors |
| `async_fifo` | ALL TESTS PASSED | 2 RDC errors |
| `apbxclk` | ALL TESTS PASSED | 3 RDC errors |

This is the existence proof for the Monday claim: **functional pass does not imply CDC/RDC-clean**.

### 5. Tooling

- `scripts/generate_openrouter.py` — one generation attempt via OpenRouter
- `scripts/evaluate_generated.py` — compile-check generated RTL against the TB
- `scripts/run_jasper_generated.csh` — JasperGold on a generated file (same SDC/clocks as the benchmark)

---

## What we did *not* do

- Did not change Llama-generated RTL after the fact
- Did not change `benchmarks/*/original/` or `benchmarks/*/fixed/`
- Did not leak reference RTL into prompts
- Did not run RTLCoder, VerilogCoder, or other models yet
- Did not expand from 11 circuits to 100–150
- Did not run synthesis scoring
- Did not claim a general result about all LLMs and CDC

---

## Next plan

### Before / at Monday

1. Push the local commit if it is not on GitHub yet (`git push origin main`).
2. Slides (6–8):
   - Problem and novelty (sim ≠ CDC)
   - Benchmark structure (original vs fixed, same tests for every model)
   - Llama 3.3 70B table (4/18 compile, 0/18 sim)
   - Human-repaired examples (3/3 sim pass, 0/3 CDC-clean)
   - 2–3 concrete violations (`WANOTL`; `RST_NO_SYNC`; undeclared `M_PRESETn`)
   - Limitations: 70B not 405B; 3-circuit pilot; draft prompts
3. Ask the advisor: keep the 3-circuit protocol, grow the circuit set, or add a second model first.

### After Monday (in order)

1. **Freeze the three prompts** after advisor review (still no reference RTL, no Gray/2-flop hints).
2. **Second model** on the same 3 × 2 × 3 setup:
   - RTL-finetuned: RTLCoder (GPU/Colab; not OpenAI)
   - Agentic (if time): VerilogCoder
   - Skip ComplexVCoder unless a public repo appears
3. **Same evaluator** for every model: compile → sim (with timeout) → JasperGold → table.
4. Grow the dataset toward **100–150** circuits using the same `benchmarks/<name>/` layout.
5. Later: assertions + synthesis as extra score columns.
6. Paper/experiment hygiene: multiple seeds, keep all failures, never overwrite attempts.

---

## How to talk about results

**Say:** This Llama 3.3 70B pilot compiled 4/18 designs and passed 0 functional tests. Separately, we showed three human-written circuits that pass the same tests and still fail JasperGold CDC/RDC. That is the gap the benchmark is built to measure.

**Do not say:** Models cannot detect CDC. Llama produced working but CDC-unsafe RTL. The human-repaired files are model outputs.
