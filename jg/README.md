# JasperGold CDC setup + SDC-completeness checks

Per-design JasperGold CDC scripts for **all 11 CDC designs** in the dataset,
plus a reusable driver that also validates whether each SDC is **complete**.

## Layout
- `lib/cdc_run.tcl` — reusable driver (`cdc_run <top> <rtl_files> <sdc> <std>`).
- `<design>.tcl` — one thin wrapper per CDC design (sets files + calls the driver).

## The 11 CDC designs

| Repo | Design | Clocks (async) | Resets | Elaborates standalone? |
|------|--------|----------------|--------|------------------------|
| ZipCPU | `apbxclk` | S_APB_PCLK / M_APB_PCLK | S_PRESETn (low) | yes |
| ZipCPU | `axixclk` | S_AXI_ACLK / M_AXI_ACLK | S_AXI_ARESETN (low) | yes (+afifo.v) |
| ZipCPU | `wbxclk` | i_wb_clk / i_xclk_clk | i_reset (high) | yes (+afifo.v) |
| dpretet | `async_fifo` | wclk / rclk | wrst_n / rrst_n (low) | yes |
| dpretet | `async_bidir_fifo` | a_clk / b_clk | a_rst_n / b_rst_n (low) | yes |
| dpretet | `async_bidir_ramif_fifo` | a_clk / b_clk | a_rst_n / b_rst_n (low) | yes (RAM external) |
| pulp_platform | `cdc_2phase` | src_clk_i / dst_clk_i | src/dst_rst_ni (low) | yes |
| pulp_platform | `cdc_4phase` | src_clk_i / dst_clk_i | src/dst_rst_ni (low) | yes |
| pulp_platform | `cdc_2phase_clearable` | src_clk_i / dst_clk_i | src/dst_rst_ni (low) | **NO — needs common_cells** |
| verilog_axis | `axis_async_fifo` | s_clk / m_clk | s_rst / m_rst (high) | yes |
| verilog_axis | `axis_async_fifo_adapter` | s_clk / m_clk | s_rst / m_rst (high) | yes |

> `cdc_2phase_clearable` `include`s pulp-platform `common_cells` headers
> (`registers.svh`, `assertions.svh`) and instantiates `cdc_reset_ctrlr`.
> Provide a `common_cells` checkout (see its wrapper) before running it.

## How to run

```bash
export DS=/home/afsara/CDC/dataset
jaspergold $DS/jg/async_fifo.tcl        # or any <design>.tcl
```

Reports are written to `cdc_reports/<top>/`.

## Checking SDC completeness (the key part)

JasperGold independently **infers** clocks and resets from the RTL. Completeness
= *does the SDC declare everything JasperGold infers, with no unconstrained flops?*

The driver dumps:
- `cdc_reports/<top>/inferred_clocks.rpt` — clocks JasperGold detected
- `cdc_reports/<top>/inferred_resets.rpt` — resets JasperGold detected
- `cdc_reports/<top>/cdc_crossings.rpt`   — the CDC paths found

**Verdict:** the SDC is complete iff
1. every clock/reset in the *inferred* reports is also in the design's `.sdc`, and
2. JasperGold reports **0 unconstrained / undefined-clock** registers.

Any clock/reset JasperGold infers that is **not** in the SDC is a missing
`create_clock` / reset declaration — add it and re-run. For these designs the
expected result is exactly **2 asynchronous clocks** per design; if JasperGold
reports a 3rd (e.g. an internally generated clock), the SDC needs it too.

## VERSION NOTE
Lines tagged `;##CONFIRM##` in `lib/cdc_run.tcl` use the JasperGold CDC app
`check_cdc` command family, whose subcommand names vary slightly by release.
Confirm them once against your install with `help check_cdc`. Everything else
(`clear`, `analyze`, `elaborate`, `read_sdc`, `report`) is standard.
