# ComplexVCoder vs Qwen — functional and CDC eval (13 Sep 2026)

**Who:** Faiza (`ft2335`)  
**Where scored:** NYU Tandon ecs05 (`ecs05.poly.edu`)  
**Where generated:** ComplexVCoder on Torch HPC (H200); Qwen via OpenRouter  
**Repo on ecs05:** `/home/ft2335/dataset`

These are two different experiment trees. CDC never ran on either scored set because **JasperGold only starts after Xcelium prints `ALL TESTS PASSED`**.

---

## How we score

Every generated `.v` goes through three gates:

1. **Compile** — Xcelium elaborates it in place of golden RTL.
2. **Functional** — same testbench, same clocks. Pass = `$display` of `ALL TESTS PASSED`. Fail = `TESTS FAILED`, `TIMEOUT` (hung 50 µs), or no sim result.
3. **CDC** — JasperGold structural CDC/RDC. Only if step 2 passed. Clean = 0 CDC errors and 0 RDC errors.

`cdc_explicit` is only a **prompt**. It does not change the testbench or Jasper script.

Golden / Torch extract (`/home/ft2335/dataset/torch`) is a separate tree: that is **fixed RTL**, not LLM output. Those 44 circuits already pass functional sim; a subset has been Jasper-clean.

---

## ComplexVCoder (scored 13 Sep 2026)

**Path:** `complexvcoder/` (symlink `experiments/complexvcoder/`)

Not a raw Qwen dump. Pipeline is English → **GIR** (JSON sketch) → Verilog. Torch metadata:

- model: `Qwen/Qwen2.5-Coder-7B-Instruct` (not the paper’s 32B)
- GPU: NVIDIA H200
- `official_implementation: false` (paper-style reimplementation)
- 27 of 264 planned attempts (44 circuits × 2 prompts × 3)

Circuits in this zip: `afifo`, `apb_cdc`, `apb_regs`, `apbslave`, `apbxclk`.

### Score

| Gate | Result |
|---|---|
| Compile | **8 / 27** |
| Functional | **0 / 27** |
| CDC (Jasper) | **0 / 27** (never started) |

| Circuit | Compile | Functional | CDC |
|---|---|---|---|
| afifo | 4/6 | 0 — 7 TB mismatches or TIMEOUT | never ran |
| apb_cdc | 1/6 | 0 — `TESTS FAILED (1)` | never ran |
| apb_regs | 0/6 | — | — |
| apbslave | 3/6 | 0 — protocol fail or TIMEOUT | never ran |
| apbxclk | 0/3 | — | — |

Summary JSON: `complexvcoder/all_generated_eval_summary.json`

### Why function fails (compile-pass examples)

- **afifo** `cdc_explicit` 001: two independent counters, not one Gray occupancy. Write-clock always-block also drives `o_rd_empty`; read-clock drives `o_wr_full`. Full/empty cannot stay consistent across clocks → wrong data or hang.
- **apb_cdc** functional 003: destination APB outputs (`dst_psel_o`, `dst_paddr_o`, …) are updated on **`src_pclk_i`**. Single-clock APB slave pretending to be a bridge.
- **apbslave**: SETUP vs ACCESS is wrong (`PSEL && PENABLE` from IDLE). APB needs SETUP (`PSEL && !PENABLE`) then ACCESS.
- **apb_regs / apbxclk**: compile errors (`WANOTL`, `UNDIDN`, `CUVMUR` missing submodules, type errors). GIR listed ports but RTL never instantiated helpers.

`cdc_explicit` did not help. GIR for afifo says “choose a safe crossing yourself” and then lists **no** Gray pointers and **no** 2-flop instances.

---

## Qwen 2.5 Coder 32B (OpenRouter pilot — not scored 13 Sep)

**Path:** `experiments/qwen-2.5-coder-32b-instruct/`  
**Generated:** 23 Aug 2026, one-shot Verilog, no GIR.

18 files: `cdc_2phase`, `async_fifo`, `apbxclk` × 2 prompts × 3 attempts. No `results.json` and no Jasper report for this folder.

Many `.v` files are **truncated** (OpenRouter HTTP 500): `async_fifo` and `apbxclk` cut off mid-port. Those will not compile.

Complete `cdc_2phase` files still fail:

- syntax: `logic [WIDTH-1:]`, `src_ready <= 1'b;`
- CDC: 2-flops `src_valid_i` into dst, then samples raw `src_data_i` / `src_valid_i` on `dst_clk_i`
- raw `dst_ready_i` used on `src_clk_i`
- `dst_valid_o` assigned from two always-blocks
- dual reset unsynchronized

To score it on ecs05:

```tcsh
setenv PATH /eda/cadence/XCELIUM2603/tools.lnx86/inca/bin/64bit:/eda/cadence/JASPER/bin:$PATH
setenv DS /home/ft2335/dataset
cd /home/ft2335/dataset
python3 scripts/eval_all_generated.py --model-dir experiments/qwen-2.5-coder-32b-instruct
```

Expect compile failures on truncated files, then 0 functional / 0 CDC.

---

## Why CDC is 0

Today’s CDC number is 0 because **Jasper never started**. That is a pipeline rule, not a Jasper verdict.

If Jasper were forced on the compile-pass RTL, it would still fail. Same families as golden-vs-broken and `experiments/human_repaired/` (those **do** pass the TB and still fail Jasper):

| Type | What the model did | Jasper tag |
|---|---|---|
| **A** | Raw `wrst_n` / `src_rst_ni` into FFs with no sync-deassert | `RST_NO_SYNC` |
| **B** | `always @(posedge clkA or negedge rstB)` — foreign reset | `RDC_RS_DFRS` |
| **C** | `count = wptr - rptr` or two binary counts, no Gray | `DATA_*` / `CONV_*` |
| **D** | Control bit (`valid`, `req`, `ack`, `ready`) sampled on the other clock with 0 or 1 flop | `CDC` / `CONV` |
| **E** | Multi-bit data crossed without hold-until-handshake | `DATA_*` / `HANDSHAKE_*` |
| **F/G** | Abort/reset pulse or combo mux on an async-reset pin | `RST_PH_GLCH` |
| **H** | Two resets, no common reset then per-clock sync-deassert | `RDC_RS_DFRS` |

0-delay Xcelium often **cannot** see C/D/E. Human-repaired `cdc_2phase` does `src_ready_o = (src_req == dst_ack)` with no synchronizer — TB still passes. That is why CDC is a second score.

---

## Assertions for a future CDC-aware testbench

These are **simulation SVA**. They catch the same bugs Jasper flags. They do **not** replace Jasper. Enable with `+define+CDC_SVA` in `xrun`.

Positive test: bind on golden `benchmarks/<name>/fixed/rtl` — must not fire.  
Negative test: bind on `experiments/human_repaired/*/generated/` — Type C/D/B must fire even if the TB still says `ALL TESTS PASSED`.

Priority (same order Jasper already uses to kill LLM passes): **B**, **A**, **C**, **D**, then E/F/G/H.

```systemverilog
// cdc_sva.sv — bind into the 3 pilots.

`ifndef CDC_SVA_SV
`define CDC_SVA_SV

`define CDC_DIS(rst) disable iff (!(rst))

property p_data_hold(clk, rst_n, valid, ready, data);
  @(posedge clk) `CDC_DIS(rst_n)
    (valid && !ready) |=> $stable(data) && valid;
endproperty

property p_common_rst_idle(clk, rst_a, rst_b, busy);
  @(posedge clk)
    (!rst_a || !rst_b) |-> !busy;
endproperty

// ---------- cdc_2phase ----------
module cdc_2phase_sva #(parameter WIDTH = 1) (
  input src_rst_ni, src_clk_i, src_valid_i, src_ready_o,
  input [WIDTH-1:0] src_data_i,
  input dst_rst_ni, dst_clk_i, dst_valid_o, dst_ready_i,
  input [WIDTH-1:0] dst_data_o
);
  a_dst_hold: assert property (
    p_data_hold(dst_clk_i, dst_rst_ni, dst_valid_o, dst_ready_i, dst_data_o)
  );

  a_dual_rst: assert property (
    p_common_rst_idle(dst_clk_i, src_rst_ni, dst_rst_ni, dst_valid_o)
  );

  bit outstanding;
  always @(posedge src_clk_i or negedge src_rst_ni)
    if (!src_rst_ni) outstanding <= 1'b0;
    else if (src_valid_i && src_ready_o) outstanding <= 1'b1;
  always @(posedge dst_clk_i or negedge dst_rst_ni)
    if (!dst_rst_ni) ;
    else if (dst_valid_o && dst_ready_i) outstanding <= 1'b0;

  a_one_outstanding: assert property (
    @(posedge src_clk_i) `CDC_DIS(src_rst_ni)
      (src_valid_i && src_ready_o) |-> !outstanding
  );
endmodule

bind cdc_2phase cdc_2phase_sva #(.WIDTH(WIDTH)) u_sva (.*);

// ---------- afifo (ZipCPU ports — ComplexVCoder used these) ----------
module afifo_sva #(
  parameter LGFIFO = 3, WIDTH = 16
)(
  input i_wclk, i_wr_reset_n, i_wr, o_wr_full,
  input [WIDTH-1:0] i_wr_data,
  input i_rclk, i_rd_reset_n, i_rd, o_rd_empty,
  input [WIDTH-1:0] o_rd_data
);
  a_rst_empty: assert property (
    @(posedge i_rclk)
      $rose(i_rd_reset_n) |-> o_rd_empty
  );
  a_rst_not_full: assert property (
    @(posedge i_wclk)
      $rose(i_wr_reset_n) |-> !o_wr_full
  );
endmodule

bind afifo afifo_sva #(.LGFIFO(LGFIFO), .WIDTH(WIDTH)) u_sva (.*);

// ---------- apbxclk ----------
module apbxclk_sva #(
  parameter C_APB_ADDR_WIDTH = 12,
  parameter C_APB_DATA_WIDTH = 32
)(
  input S_APB_PCLK, S_PRESETn, S_APB_PSEL, S_APB_PENABLE, S_APB_PREADY,
  input M_APB_PCLK, M_PRESETn,
  input M_APB_PSEL, M_APB_PENABLE, M_APB_PREADY
);
  // Type B: master-domain FFs must not async-reset on S_PRESETn
  a_mclk_uses_mreset: assert property (
    @(posedge M_APB_PCLK)
      $fell(S_PRESETn) && M_PRESETn |-> 1'b0
  );
  a_s_hold: assert property (
    @(posedge S_APB_PCLK) `CDC_DIS(S_PRESETn)
      (S_APB_PSEL && S_APB_PENABLE && !S_APB_PREADY)
      |=> S_APB_PSEL && S_APB_PENABLE
  );
endmodule

bind apbxclk apbxclk_sva #(
  .C_APB_ADDR_WIDTH(C_APB_ADDR_WIDTH),
  .C_APB_DATA_WIDTH(C_APB_DATA_WIDTH)
) u_sva (.*);

`endif
```

Structural lint before sim (Xcelium will not infer these from ports):

```python
import re
BAD = [
    (r"wptr\s*-\s*rptr|count\s*=\s*wptr", "C binary pointer CDC"),
    (r"always\s*@\s*\(\s*posedge\s+(\w+).*negedge\s+(?!.*\1)", "B foreign async reset"),
    (r"src_ready_o\s*=\s*\(.*src_req.*dst_ack", "D combo req==ack across clocks"),
    (r"always\s*@\s*\(\s*posedge\s+dst_clk[\s\S]{0,200}src_data_i", "E sample async data"),
]
```

---

## How to re-run on ecs05

```tcsh
setenv PATH /eda/cadence/XCELIUM2603/tools.lnx86/inca/bin/64bit:/eda/cadence/JASPER/bin:$PATH
setenv DS /home/ft2335/dataset
cd /home/ft2335/dataset
python3 scripts/eval_all_generated.py --model-dir experiments/complexvcoder
```

Run Cadence from an interactive `[ft2335@ecs05]` tcsh (licenses), not from a Cursor agent job.

---

## Bottom line

- ComplexVCoder (7B + GIR, 27 attempts): **8 compile, 0 functional, 0 CDC**.
- Qwen 32B one-shot (18 pilots): **not scored 13 Sep**; files are truncated or CDC-unsafe. Same expected outcome.
- The `cdc_explicit` prompt did not produce Gray pointers or 2-flop sync.
- CDC is 0 because sim never passed. Human-repaired RTL shows that even a functional pass can still fail Jasper (types C/D/B).
