---
marp: true
theme: default
paginate: true
size: 16:9
title: CDC-Aware RTL Generation Benchmark
description: Advisor update — 24 August 2026
style: |
  section {
    font-family: "Aptos", "Arial", sans-serif;
    font-size: 28px;
    color: #172033;
    background: #f7f8fa;
    padding: 52px 68px;
  }
  h1 { color: #17365d; font-size: 46px; margin-bottom: 18px; }
  h2 { color: #17365d; font-size: 36px; margin-bottom: 16px; }
  strong { color: #9b2c2c; }
  table { font-size: 21px; width: 100%; }
  th { background: #dfe7f2; color: #17365d; }
  td, th { padding: 8px 10px; }
  code { color: #17365d; background: #e8edf3; }
  blockquote {
    border-left: 8px solid #9b2c2c;
    background: #eef1f5;
    padding: 16px 22px;
    font-size: 31px;
  }
  .small { font-size: 20px; color: #4b5563; }
  .key { font-size: 37px; color: #9b2c2c; font-weight: 700; }
  .ok { color: #216e39; font-weight: 700; }
  .bad { color: #9b2c2c; font-weight: 700; }
  .two-col { display: grid; grid-template-columns: 1fr 1fr; gap: 34px; }
  footer { color: #6b7280; }
---

# CDC-Aware RTL Generation Benchmark

## Can an LLM generate RTL that is both functionally correct and CDC/RDC-safe?

<br>

<div class="key">Latest result: GPT-5.6 Sol had 29 functional passes; JasperGold passed 0 of them.</div>

<br>

**Faiza · Advisor update · 24 August 2026**

---

# Motivation and research question

Most RTL-generation evaluations stop at:

1. Does the RTL compile?
2. Does it pass a functional testbench?

That misses clock-domain and reset-domain failures that ordinary digital
simulation does not model.

> **Research question:** Can generated RTL satisfy the functional specification
> while also having no unsafe CDC/RDC crossings?

**Claim supported by current data:** functional pass does **not** imply
CDC/RDC-clean.

<div class="small">We do not yet claim that all models fail at CDC-aware generation.</div>

---

# Benchmark and evaluation pipeline

<div class="two-col">
<div>

## Dataset

- **44 circuits** packaged with RTL, TB, SDC, Jasper
- Original and CDC/RDC-fixed RTL kept separate
- Golden RTL is never in the prompt
- Generation still uses a **3-circuit pilot**

</div>
<div>

## Pilot tasks

- `cdc_2phase` — handshake CDC
- `async_fifo` — asynchronous FIFO
- `apbxclk` — APB clock bridge
- **functional** prompt: ports and behavior
- **CDC-explicit** prompt: same, plus “must be CDC/RDC-safe” — no Gray-code or 2-flop hints

</div>
</div>

### Scoring (identical for every model)

**Prompt → generated RTL → Xcelium compile → functional sim → JasperGold only after sim pass**

---

# Packaged CDC circuits: 44/44 tool-clean

| Set | Count | Functional sim | JasperGold |
|---|---:|---|---|
| Frozen pilot | **11** | 11/11 PASS | 11/11 CLEAN |
| Catalog imports | **19** | 19/19 PASS | 19/19 CLEAN |
| Additional CDC circuits | **14** | 14/14 PASS | 14/14 CLEAN |
| **Total packaged** | **44** | **44/44 PASS** | **44/44 CLEAN** |

Families added: Gray and 2-phase FIFOs, reset controllers, isochronous handshake,
APB/AXI-Lite CDC, and synchronizers.

<div class="small">These 44 are packaged references. They are not 44 LLM generation results. Specs for the extra 33 remain draft.</div>

---

# Frozen one-shot baselines

## Same scope: 3 circuits × 2 prompts × 3 attempts = 18/model

| Model | Base | Compile | Functional | CDC-clean |
|---|---|---:|---:|---:|
| Llama 3.3 70B Instruct | Llama | **4/18** | **0/18** | **0/18** |
| RTLCoder-v1.1 4-bit GGUF | **Mistral** | **1/18** | **0/18** | **0/18** |
| RTLCoder-DeepSeek-v1.1 fp16 | **DeepSeek** | **5/18** | **0/18** | **0/18** |

Typical failures: invalid assignments, truncated RTL, broken APB handshake,
CDC timeout. CDC-explicit wording alone did not produce a functional pass.

<div class="small">RTLCoder-v1.1 GGUF is Mistral-based. RTLCoder-DeepSeek is a separate fine-tune. Pass@20 and repair loops are not merged into this table.</div>

---

# Main result: GPT-5.6 Sol

## 3 circuits × 2 prompts × 10 attempts · compile → sim → Jasper after sim pass

| Circuit | Prompt | Compile | Functional | Jasper-clean |
|---|---|---:|---:|---:|
| `cdc_2phase` | functional | <span class="ok">10/10</span> | <span class="ok">10/10</span> | <span class="bad">0/10</span> |
| `cdc_2phase` | cdc_explicit | <span class="ok">10/10</span> | <span class="ok">10/10</span> | <span class="bad">0/10</span> |
| `async_fifo` | functional | <span class="ok">10/10</span> | <span class="bad">0/10</span> | not run |
| `async_fifo` | cdc_explicit | <span class="ok">10/10</span> | <span class="bad">0/10</span> | not run |
| `apbxclk` | functional | <span class="ok">9/9</span> | <span class="ok">9/9</span> | <span class="bad">0/9</span> |
| `apbxclk` | cdc_explicit | — | — | credits exhausted |

**29 / 29** functional passes failed Jasper. Typical tags: `RST_PH_GLCH`, `RDC_RS_DFRS`.

<div class="small">Jasper runs only after sim pass. FIFO compiled but never passed the testbench. 49 of 60 attempts evaluated.</div>

---

# Other protocols (not mixed into the Sol table)

| Protocol | Result | Takeaway |
|---|---|---|
| Llama compile-repair | 6/6 compile; 1/6 functional; 0 clean | Compiler feedback fixes syntax, not CDC |
| RTLCoder-DeepSeek Pass@20 | 73 RTL; 7 compile; 0 functional | More samples did not find a sim pass |
| Jasper on those 7 compiles | 5 RDC fail; 2 zero crossings | Zero reported violations is not automatically “clean” |

One-shot, extra sampling, and repair remain **separate columns**.

---

# Limitations

- LLM generation is still the **3-circuit pilot**, not all 44.
- GPT-5.6 Sol is **49/60**: `apbxclk` CDC-explicit and one functional attempt remain (credits).
- OpenAI GPT-5.6 does not expose temperature, top-p, or seed.
- RTLCoder-DeepSeek Pass@20 has no `apbxclk` yet.
- Specs for the extra 33 circuits are still draft.
- No synthesis, area, or assertion score yet.

---

# Proposed next phase

## Ask for this meeting

1. Resume the remaining **11 GPT-5.6 Sol** attempts after credits are added.
2. Run **one more API model** on the same 3 × 2 × 10 loop.

## After that

3. Finish RTLCoder-DeepSeek Pass@20 when GPU is available.
4. Expand generation from the 3-circuit pilot across the packaged 44.

---

# Thank you

<div class="key">Questions?</div>

<br>

Compilation and simulation are necessary, but not sufficient, for generated CDC RTL.

**Faiza · CDC-Aware RTL Generation · 24 August 2026**
