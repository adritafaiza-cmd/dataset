# Daily progress: formal contracts and enhanced CDC TB scoring

**Researcher:** Faiza  
**Work period:** 3–4 October 2026  
**Scope:** Repair remaining SymbiYosys golden contracts, score generated RTL on newly eligible circuits, and run enhanced CDC testbenches only on compile-and-functionally-correct generated RTL.

## Executive summary

Today closed most of the formal-eligibility gap and added a third scoring gate after compile and functional simulation.

- Golden formal contracts now prove on **43/44** circuits. Only `apb_regs` remains `FORMAL_UNSUPPORTED`.
- Golden RTL under `benchmarks/*/fixed/rtl/` was **not** edited. Only `formal/<circuit>/formal.sv` and `formal/<circuit>/golden.sby` were rewritten.
- Newly eligible generated RTL (19 circuits, 950 files): **161 proved (16.9%)**. ComplexVCoder 78/570, Llama 32/190, Qwen 51/190.
- Enhanced CDC TBs were run only on generated files that already compiled and passed the functional TB: **301 files, 109 PASS, 192 FAIL**.
- **0 of 43 multi-clock CDC files passed** the enhanced TB. Almost all 109 PASSes are single-clock synchronizer or reset pipes.

These results show that functional-pass RTL is often still not CDC-aware. They do **not** prove analog metastability, Jasper CDC-clean, or a statistical model-versus-golden CDC gap.

## What was done

### 1. Formal contracts for the remaining 20 circuits

Fourteen circuits had a real BMC counterexample on golden, not just induction `UNKNOWN`. Six others were previously `UNSUPPORTED` because Yosys could not elaborate the old harness.

| Previous status | Circuits |
|---|---|
| Golden FAIL | `sync`, `sync_multistage`, `sync_wedge`, `pulse_sync`, `edge_propagator`, `axis_register`, `axis_adapter`, `axis_fifo`, `axis_switch`, `apbxclk`, `apb_cdc`, `axil_cdc`, `axixclk`, `spi_master_slave` |
| Unsupported | `uart16550`, `i2c_master`, `axi_dma`, `axidma`, `cdc_2phase_clearable`, `apb_regs` |

Typical contract bugs that were fixed:

- `$global_clock` / async-reset mismatch on the synchronizer family
- over-strong AXIS age/livelock properties
- `$rose` / `$past` sampled on the wrong clock for APB/AXI CDC
- SPI `wr_ack` versus `wren` same-cycle assumption
- undriven clock versus port name `clk_i`
- `axidma` placeholder `// ...` inside a `FORMAL` ifdef that broke Yosys
- missing slang `--top` / vendor includes for `cdc_2phase_clearable`

`apb_regs` still cannot be a golden-pass contract: slang elaborates the typed structs, but BMC does not preserve `pready == psel && penable`.

### 2. What `formal.sv` and `golden.sby` contain

Each eligible circuit has two files under `formal/<circuit>/`:

- **`formal.sv`**: a small digital contract. It instantiates the DUT, constrains clocks/resets/inputs with `assume`, and checks a few bounded properties with `assert` / `cover` (2-flop delay, FIFO/stream hold, reset release, APB/AXI handshake, pulse width). It is not a metastability model.
- **`golden.sby`**: the SymbiYosys recipe (engines, depth, top, file list). The eligibility gate is `formal/<circuit>/golden_prove/PASS` on golden RTL.

Policy: `formal/README.md`. Runner: `scripts/evaluate_symbiyosys_eligible.py`.

### 3. Formal scoring of generated RTL

A candidate is scored only if that circuit’s golden prove already PASSed. Same-stem extra golden files (for example golden `sync.sv` next to generated `sync.v`) are skipped so both modules are not elaborated together.

Newly eligible generated results:

| Model | Files | Proved |
|---|---:|---:|
| ComplexVCoder | 570 | **78** |
| Llama 3.3 70B | 190 | **32** |
| Qwen 2.5 Coder 32B | 190 | **51** |
| **Total** | **950** | **161 (16.9%)** |

Remaining formal issues, not model failures:

- `sync_multistage` still records ELAB on many files because golden `sync.sv` and the generated top collide
- one leftover `apb_regs` unsupported circuit
- formal PASS is a contract proof, not “CDC clean”

Summaries: `formal/new20_{complexvcoder,llama,qwen}_summary.json`, `formal/new20_rescore_svstem_summary.json`, `formal/eligible_generated_summary.json`.

### 4. Enhanced CDC TB on compile + functional-pass RTL only

Runner: `scripts/run_enhanced_cdc_functional.py`.  
Dump: `enhanced_cdc_tb/results/functional_generated.json`.

Input set: ComplexVCoder Xcelium functional-pass (173) plus Llama/Qwen Icarus functional-pass (128) = **301**.

| Model | Files | Enhanced TB pass |
|---|---:|---:|
| ComplexVCoder | 173 | **85** |
| Llama | 54 | **10** |
| Qwen | 74 | **14** |
| **Total** | **301** | **109** |

| Circuit class | Files | PASS | FAIL |
|---|---:|---:|---:|
| Single-clock sync/reset | 205 | 102 | 103 |
| Multi-clock CDC | 43 | **0** | 43 |
| Single-clock protocol (`arbiter`, `apbslave`, `axis_*`) | 53 | 7 | 46 |

Strongest enhanced-TB PASSes: `synchronizer` 39/48, `sync_multistage` 21/28, `areset_sync` 22/46, `sync` 18/30, `axis_register` 6/14.

Zero enhanced-TB pass among functional-pass files: `data_sync`, `edge_propagator`, `sync_wedge`, `pulse_sync`, `arbiter`, and the few FIFOs/handshakes that reached this gate.

**22 circuits were not run** because no generated file compiled and passed functional sim: `afifo`, `apb_cdc`, `apb_regs`, `apbxclk`, `areset_deassert_sync`, `async_bidir_fifo`, `async_bidir_ramif_fifo`, `async_fifo`, `axi_dma`, `axidma`, `axis_adapter`, `axis_async_fifo`, `axis_async_fifo_adapter`, `axixclk`, `cdc_2phase_clearable`, `cdc_fifo_gray_clearable`, `cdc_reset_ctrlr`, `i2c_master`, `isochronous_4phase_handshake`, `spi_master_slave`, `uart16550`, `wbxclk`.

Golden enhanced TBs remain 42/43 PASS. `spi_master_slave` golden still fails that TB, so it is not a valid gate yet.

### 5. RTLCoder on Torch

Job **19128466** (`rtlcoder-3prompt`, 44 × 3 × 10 = 1,320) was submitted on Torch HPC. Last confirmed state: `R` on `gh112`, writing `experiments/rtlcoder-deepseek-3prompt-10attempt-v1`. SSH logout does not stop Slurm.

**Enter the HPC MFA code:** [https://login.microsoft.com/device](https://login.microsoft.com/device)  
Login steps and `squeue` commands: [TORCH_HPC.md](TORCH_HPC.md).

## What these data can and cannot claim

**Supported**

- Functional-pass generated RTL still fails a large fraction of enhanced CDC/reset monitors (192/301).
- Every multi-clock CDC file that reached that gate failed (43/43).
- Formal contracts now exist for 43 circuits, and 16.9% of newly eligible generated files proved those contracts.

**Not supported**

- “The benchmark verifies CDC” or “these files are CDC-clean.”
- Metastability, MTBF, missing two-flop structure, or Gray-pointer correctness. Simulation cannot show those; `FIFO_GRAY_POINTER` currently only checks X on pointer/status bits.
- Treating `arbiter` / `axis_*` / `apbslave` PROTOCOL failures as CDC errors.
- Treating exact 2-flop cycle-match (`CDC_SYNC_STAGE_BEHAVIOR`) as a CDC safety proof. A 3-flop (safer) design would fail that check.

## Known TB / scoring gaps (not yet fixed)

1. `areset_sync` models reset as a data pipe; it lacks async-assert / sync-deassert checks that `areset_deassert_sync` already has.
2. `synchronizer` has no `RESET_ASYNC_ASSERT` (unlike `sync`).
3. Pulse/edge TBs wait for idle before the next event, so they miss pulse-while-busy and back-to-back edges.
4. Dual-clock TBs use one fixed clock ratio.
5. The enhanced runner records many `areset_sync` fails as untyped `TESTS FAILED` because it does not treat `RESET VIOLATION` as a first-class prefix.
6. Formal and enhanced-TB summaries are not yet merged into one publication table.

## Claim that is currently supported

> After repairing golden formal contracts (43/44 prove), newly eligible generated RTL proved 161/950 formal contracts. Independently, of 301 generated files that already compiled and passed functional simulation, 109 passed the enhanced CDC/reset TB and 0/43 multi-clock CDC files passed. This is digital observable / contract evidence, not a Jasper or metastability proof.

## Main artifacts

- Formal policy: `formal/README.md`
- Formal runner: `scripts/evaluate_symbiyosys_eligible.py`
- Formal summaries: `formal/new20_*_summary.json`, `formal/eligible_generated_summary.json`
- Enhanced TBs: `enhanced_cdc_tb/`
- Enhanced functional-pass runner: `scripts/run_enhanced_cdc_functional.py`
- Enhanced results: `enhanced_cdc_tb/results/functional_generated.json`
- ComplexVCoder functional eval: `experiments/complexvcoder-3prompt-10attempt-v1/all_generated_eval_summary.json` (1320 files; 501 compile, 173 sim)
- Llama/Qwen functional eval: `experiments/multi-llm-observable-v1/openrouter/icarus_observable_summary.json`
