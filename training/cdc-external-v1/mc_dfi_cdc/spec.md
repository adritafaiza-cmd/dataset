Implement the SystemVerilog module `mc_dfi_cdc`.

THE single clock-domain crossing of the DFI 2.1 plane. All traffic

Functional contract and interface notes:

Module: mc_dfi_cdc
Purpose: THE single clock-domain crossing of the DFI 2.1 plane. All traffic
between the controller domain (ctl_clk: AXI IFC + scheduler + CAMs)
and the PHY DFI domain (dfi_clk: phase-packer + PHY) crosses here,
and ONLY through gaxi_fifo_async (Gray-pointer) FIFOs — no
hand-rolled synchronizers, no open-loop bit crossings.
Extracted from pumice_dfi_cdc during Phase 2 common-plane reorg
(2026-10-10).
ctl -> phy : cmd, wrdata, init_start(token)
phy -> ctl : rddata, init_complete(token)
Level signals (init_start / init_complete) cross as EVENT TOKENS: a rising
edge on the source side pushes a 1-bit token; the sink pops it and sets a
sticky latch. init is monotonic (once); leveling re-runs are future work.
Payloads are opaque buses — the DFI top packs/unpacks {op,...}/{data,...}.

Required clock and reset behavior:

- Clock ports: ctl_clk, dfi_clk.
- Reset ports: ctl_rstn, dfi_rstn.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- gaxi_fifo_async: gaxi_fifo_async #( .DATA_WIDTH (CMD_DW), .DEPTH (CMD_DEPTH), .USE_JOHNSON (USE_JOHNSON), .N_FLOP_CROSS(N_FLOP_CROSS) ) u_cmd_fifo ( .axi_wr_aclk (ctl_clk), .axi_wr_aresetn(ctl_rstn), .axi_rd_aclk (dfi_clk), .axi_rd_aresetn(dfi_rstn), .wr_valid (cmd_valid_i), .wr_ready (cmd_ready_o), .wr_data (cmd_data_i), .rd_ready (pcmd_ready_i), .rd_valid (pcmd_valid_o), .rd_data (pcmd_data_o) );
- gaxi_fifo_async: gaxi_fifo_async #( .DATA_WIDTH (WD_DW), .DEPTH (WD_DEPTH), .USE_JOHNSON (USE_JOHNSON), .N_FLOP_CROSS(N_FLOP_CROSS) ) u_wd_fifo ( .axi_wr_aclk (ctl_clk), .axi_wr_aresetn(ctl_rstn), .axi_rd_aclk (dfi_clk), .axi_rd_aresetn(dfi_rstn), .wr_valid (wd_valid_i && w_wtok_ready), .wr_ready (w_wd_data_ready), .wr_data (wd_data_i), .rd_ready (pwd_ready_i), .rd_valid (pwd_valid_o), .rd_data (pwd_data_o) );
- gaxi_fifo_async: gaxi_fifo_async #( .DATA_WIDTH (1), .DEPTH (WD_DEPTH), .USE_JOHNSON (USE_JOHNSON), .N_FLOP_CROSS(N_FLOP_CROSS) ) u_wtok_fifo ( .axi_wr_aclk (ctl_clk), .axi_wr_aresetn(ctl_rstn), .axi_rd_aclk (dfi_clk), .axi_rd_aresetn(dfi_rstn), .wr_valid (w_wtok_push), .wr_ready (w_wtok_ready), .wr_data (1'b1), .rd_ready (pwr_staged_pop_i), .rd_valid (pwr_staged_valid_o), .rd_data () );
- gaxi_fifo_async: gaxi_fifo_async #( .DATA_WIDTH (RD_DW), .DEPTH (RD_DEPTH), .USE_JOHNSON (USE_JOHNSON), .N_FLOP_CROSS(N_FLOP_CROSS) ) u_rd_fifo ( .axi_wr_aclk (dfi_clk), .axi_wr_aresetn(dfi_rstn), .axi_rd_aclk (ctl_clk), .axi_rd_aresetn(ctl_rstn), .wr_valid (prd_valid_i), .wr_ready (prd_ready_o), .wr_data (prd_data_i), .rd_ready (rd_ready_i), .rd_valid (rd_valid_o), .rd_data (rd_data_o) );
- gaxi_fifo_async: gaxi_fifo_async #( .DATA_WIDTH (1), .DEPTH (TOK_DEPTH), .USE_JOHNSON (USE_JOHNSON), .N_FLOP_CROSS(N_FLOP_CROSS) ) u_istart_tok ( .axi_wr_aclk (ctl_clk), .axi_wr_aresetn(ctl_rstn), .axi_rd_aclk (dfi_clk), .axi_rd_aresetn(dfi_rstn), .wr_valid (w_istart_push), .wr_ready (), .wr_data (1'b1), .rd_ready (1'b1), .rd_valid (w_istok_valid), .rd_data () );
- gaxi_fifo_async: gaxi_fifo_async #( .DATA_WIDTH (1), .DEPTH (TOK_DEPTH), .USE_JOHNSON (USE_JOHNSON), .N_FLOP_CROSS(N_FLOP_CROSS) ) u_icmp_tok ( .axi_wr_aclk (dfi_clk), .axi_wr_aresetn(dfi_rstn), .axi_rd_aclk (ctl_clk), .axi_rd_aresetn(ctl_rstn), .wr_valid (w_icmp_push), .wr_ready (), .wr_data (1'b1), .rd_ready (1'b1), .rd_valid (w_icmptok_valid), .rd_data () );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module mc_dfi_cdc #(
    parameter int CMD_DW       = 32,   // {op,rank,bank,row,col,ap} packed
    parameter int WD_DW        = 72,   // {data,strb,last}
    parameter int RD_DW        = 66,   // {data,resp,last}
    // Depths are powers of two, which is what the default Gray pointer
    // encoding requires ("even" was stale language from fifo_async_div2).
    parameter int CMD_DEPTH    = 8,
    parameter int WD_DEPTH     = 16,
    parameter int RD_DEPTH     = 16,
    parameter int TOK_DEPTH    = 4,
    parameter int N_FLOP_CROSS = 2,
    // Async-FIFO pointer encoding for all five CDC FIFOs below: 0 = Gray
    // (power-of-2 depth only), 1 = Johnson (any depth, DEPTH-bit pointers).
    // Gray by default -- Johnson is opt-in because its pointers cost DEPTH
    // bits in both domains and every synchronizer stage.
    parameter int USE_JOHNSON  = 0,
    // 1 = ctl_clk and dfi_clk are independent: five Gray-pointer async FIFOs
    //     cross them (the contract above).
    // 0 = ctl_clk and dfi_clk are THE SAME CLOCK (the Nexys A7 boards tie
    //     dfi_clk to mc_clk): the same FIFOs as synchronous gaxi_fifo_sync at
    //     the same depths, the init tokens as plain sticky levels. Same
    //     ports, same valid/ready contract, no pointer synchronizers; each
    //     crossing loses its N_FLOP_CROSS + 1 cycles of latency. The data /
    //     staged-token coupling is unchanged, so the write-staged invariant
    //     (data never behind its WR at the PHY) holds as before. Only legal
    //     when the two clock inputs are one net: the dfi-side flops below
    //     are clocked by dfi_clk and read ctl-domain signals directly.
    parameter bit DFI_CDC_EN   = 1'b1
) (
    //=========================================================================
    // Controller domain (aclk)
    //=========================================================================
    input  logic              ctl_clk,
    input  logic              ctl_rstn,
    // cmd  ctl -> phy
    input  logic              cmd_valid_i,
    output logic              cmd_ready_o,
    input  logic [CMD_DW-1:0] cmd_data_i,
    // wrdata ctl -> phy. wd_last_i marks the final DFI word of a burst: it is
    // what pushes the "burst staged" token below (the payload stays opaque).
    input  logic              wd_valid_i,
    output logic              wd_ready_o,
    input  logic [WD_DW-1:0]  wd_data_i,
    input  logic              wd_last_i,
    // init start (level) ctl -> phy
    input  logic              init_start_i,
    // rddata phy -> ctl
    output logic              rd_valid_o,
    input  logic              rd_ready_i,
    output logic [RD_DW-1:0]  rd_data_o,
    // init complete (level) phy -> ctl (sticky latch)
    output logic              init_complete_o,
    //=========================================================================
    // PHY DFI domain (dfi_clk)
    //=========================================================================
    input  logic              dfi_clk,
    input  logic              dfi_rstn,
    // cmd out (phy)
    output logic              pcmd_valid_o,
    input  logic              pcmd_ready_i,
    output logic [CMD_DW-1:0] pcmd_data_o,
    // wrdata out (phy)
    output logic              pwd_valid_o,
    input  logic              pwd_ready_i,
    output logic [WD_DW-1:0]  pwd_data_o,
    // write-burst-staged tokens (phy): one per COMPLETE burst that has crossed
    // into the wrdata FIFO. The command path pops one per WR it accepts, so a
    // WR command can never reach the PHY ahead of its data (the write analog
    // of the read aligner's op_ready backpressure). Pushed on the ctl edge that
    // accepts the burst's LAST word, through the same N_FLOP_CROSS synchronizer
    // as the data pointer, so never visible on dfi_clk before the data is.
    // With the controller's rate-matched commit + CMD_DELAY this gate is an
    // INVARIANT (never holds); the counters in pumice_dfi_cmd_path prove it.
    output logic              pwr_staged_valid_o,
    input  logic              pwr_staged_pop_i,
    // init start (level) phy (sticky latch)
    output logic              pinit_start_o,
    // rddata in (phy)
    input  logic              prd_valid_i,
    output logic              prd_ready_o,
    input  logic [RD_DW-1:0]  prd_data_i,
    // init complete (level) phy -> crosses to ctl
    input  logic              pinit_complete_i
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
