# Advisor talk — CDC-Aware RTL Generation

**Date:** 24 August 2026  
**Length:** about 10–12 minutes  
**Slides:** `CDC_Aware_RTL_Generation.pptx` (10 slides)

Speak this in first person. Pause at each `[CLICK]`. Do not read every table cell — point, then say the sentence in **bold**.

### Things not to mix up

- **44/44** is the packaged golden catalog. It is **not** 44 LLM results.
- Generation is still the **3-circuit pilot**: `cdc_2phase`, `async_fifo`, `apbxclk`.
- Two RTLCoders: the 4-bit GGUF is **Mistral**. The fp16 / Pass@20 run is **DeepSeek**.
- GPT-5.6 Sol is **49 of 60** attempts. Credits ran out; 11 remain.
- Jasper runs **only after** a functional sim pass.

---

## Slide 1 — Title (~45 s)

Good afternoon. This is an advisor update on the CDC-aware RTL generation benchmark.

The question I am trying to answer is: **can an LLM generate RTL that is both functionally correct and CDC and RDC safe?**

Most published RTL-generation work stops at compile and simulation. That is not enough for clock-domain crossing. A design can pass its testbench and still have unsafe crossings.

The number I want to leave with you is on this slide. **GPT-5.6 Sol produced 29 functional passes. JasperGold passed none of them.**

[CLICK]

## Slide 2 — Motivation (~1 min)

This is the gap I am measuring.

Typical scoring is: does it compile, and does it pass a functional testbench? Ordinary digital simulation does not model metastability, and it does not check structural clock-domain or reset-domain safety.

So a design can look correct in Xcelium and still be unsafe in JasperGold.

I am not claiming that every model fails at CDC-aware generation. I am claiming that **a functional pass does not imply CDC/RDC-clean**, and I now have a pipeline that can score both.

[CLICK]

## Slide 3 — Pipeline (~1 min 15 s)

I packaged **44 circuits** with RTL, testbench, SDC, and Jasper. Original RTL and the CDC/RDC-fixed RTL are kept separate. Golden RTL never goes into the prompt, and I never edit generated RTL.

Generation is still a **three-circuit pilot**: a handshake CDC, an asynchronous FIFO, and an APB clock bridge.

There are two frozen prompts. The **functional** prompt gives ports and behavior. The **CDC-explicit** prompt says the same thing, plus that the design must be CDC and RDC safe. It does **not** tell the model to use Gray code or a two-flop synchronizer.

Scoring is the same for every model: prompt, generated RTL, Xcelium compile, functional simulation, then **JasperGold only if simulation passed**. Failures are archived. I report compile, functional, and Jasper-clean separately.

[CLICK]

## Slide 4 — 44 packaged circuits (~1 min)

This table is the **golden catalog**, not the LLM study.

Eleven frozen-pilot circuits, nineteen catalog imports, and fourteen additional CDC circuits — Gray and two-phase FIFOs, reset controllers, isochronous handshake, APB and AXI-Lite CDC, and synchronizers. **All 44 pass functional simulation. All 44 are Jasper-clean.**

That means the evaluation tools are in place. Specs for the extra 33 are still draft. I have not yet asked a model to generate those 33.

If I say “forty-four,” I mean packaged references. The model results on the next slides are still **three circuits**.

[CLICK]

## Slide 5 — One-shot baselines (~1 min)

Same frozen scope for every local model: three circuits, two prompts, three attempts — **eighteen generations each**.

Llama 3.3 70B compiled 4 of 18. The GGUF RTLCoder compiled 1 of 18. That one is **Mistral-based**, not DeepSeek. RTLCoder-DeepSeek fp16 compiled 5 of 18. **None of them passed functional simulation, so none of them were CDC-clean.**

Typical failures were invalid assignments, truncated files, broken APB handshakes, and CDC timeout.

Telling the model “be CDC-safe” in the prompt was not enough to get a functional pass. Repair loops and Pass@20 are **separate columns**. I do not merge them into this table.

[CLICK]

## Slide 6 — GPT-5.6 Sol (main result, ~2 min 30 s)

This is the main result.

GPT-5.6 Sol, same three circuits, both prompts, **ten attempts each**. Compile, then sim, then Jasper only after sim pass.

On the two-phase handshake, all ten functional prompts compiled and passed sim. All ten CDC-explicit prompts did the same. **Jasper: 0 of 10, both prompts.**

On the async FIFO, all twenty compiled. **Zero passed the testbench**, so Jasper was not run. Compile is not the same as function.

On the APB bridge, nine of the ten functional attempts finished before credits ran out. All nine compiled, all nine passed sim, **zero were Jasper-clean**. The CDC-explicit prompt for that circuit did not run.

So: **29 of 29 simulation passes failed Jasper.** Typical tags were `RST_PH_GLCH` — a potential reset-path glitch — and `RDC_RS_DFRS` — related flops using different reset domains.

The CDC-explicit wording did not produce a clean design. OpenAI credits ran out on APB functional attempt 10, so this matrix is **49 of 60**.

If you remember one row, remember handshake and APB: they look done in simulation, and Jasper still fails.

[CLICK]

## Slide 7 — Other protocols (~1 min)

These are **not** mixed into the Sol table.

Llama with compile-error repair: all six compiled, one became functional, **none were CDC-clean**. Compiler feedback fixes syntax. It does not fix CDC.

RTLCoder-DeepSeek Pass@20: 73 candidates, 7 compiled, **0 functional**. More samples did not find a sim pass.

On those seven compiles, Jasper reported five RDC failures and two designs with **zero reported crossings**. Zero violations is not automatically “clean” for a required CDC task. Those two never passed the testbench, so they are not counted as successes.

[CLICK]

## Slide 8 — Limitations (~1 min)

I want to be explicit about scope.

Generation is still the three-circuit pilot, not all forty-four. Specs for the extra 33 are draft.

GPT-5.6 Sol is 49 of 60. Eleven attempts remain after credits ran out. The API also does not expose temperature, top-p, or seed.

RTLCoder-DeepSeek Pass@20 has no APB bridge yet. I do not yet score synthesis, area, or assertions.

[CLICK]

## Slide 9 — Next phase (~1 min)

What I would like from this meeting is two things.

First, after credits are added, **resume the remaining eleven GPT-5.6 Sol attempts**. The runner is resumable; it will not regenerate finished cells.

Second, run **one more API model** on the same 3 × 2 × 10 loop, so Sol is not a one-model anecdote.

After that: finish RTLCoder-DeepSeek Pass@20 when GPU is available, then expand generation from the three-circuit pilot across the packaged 44.

[CLICK]

## Slide 10 — Thank you (~20 s)

Thank you. Happy to take questions.

Compilation and simulation are necessary, but they are **not sufficient** for generated CDC RTL.

---

## If asked

**Is RTLCoder DeepSeek?**  
There are two. The 4-bit GGUF one-shot is Mistral RTLCoder-v1.1. The fp16 one-shot and the Pass@20 run are RTLCoder-DeepSeek.

**Did you get 44 LLM results?**  
No. Forty-four is the packaged golden set. Models have only been run on three circuits.

**Why skip Jasper on FIFO?**  
Jasper runs only after a functional pass. FIFO never passed the testbench.

**Is 0/10 CDC-explicit proof that prompting cannot work?**  
No. It shows that this wording, on this model, did not produce a Jasper-clean design. I still keep the two prompts as separate columns.

**Can you resume Sol now?**  
Not until OpenAI credits are added. Then I resume the missing eleven only.

**What would count as a success?**  
A design that compiles, passes the official testbench, **and** comes back Jasper-clean — without editing generated RTL.
