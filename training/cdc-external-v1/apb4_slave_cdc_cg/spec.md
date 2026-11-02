Implement the SystemVerilog module `apb4_slave_cdc_cg`.

Apb Slave Cdc Cg module

Functional contract and interface notes:

Module: apb4_slave_cdc_cg
Purpose: Apb Slave Cdc Cg module

Required clock and reset behavior:

- Clock ports: aclk, pclk, pclk_cg_gating, pclk_cg_idle, aclk_cg_gating, aclk_cg_idle.
- Reset ports: aresetn.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- gaxi_fifo_async: gaxi_fifo_async #( .DATA_WIDTH (APBCmdWidth), .DEPTH (CDC_FIFO_DEPTH), .USE_JOHNSON (USE_JOHNSON), .N_FLOP_CROSS (2) ) u_cmd_cdc_fifo ( .axi_wr_aclk (gated_pclk), .axi_wr_aresetn (presetn), .axi_rd_aclk (gated_aclk), .axi_rd_aresetn (aresetn), .wr_valid (w_cmd_valid), .wr_ready (int_cmd_ready), .wr_data ({w_cmd_pwrite, w_cmd_paddr, w_cmd_pwdata, w_cmd_pstrb, w_cmd_pprot}), .rd_ready (cmd_ready), .rd_valid (cmd_valid), .rd_data ({cmd_pwrite, cmd_paddr, cmd_pwdata, cmd_pstrb, cmd_pprot}) );
- gaxi_fifo_async: gaxi_fifo_async #( .DATA_WIDTH (APBRspWidth), .DEPTH (CDC_FIFO_DEPTH), .USE_JOHNSON (USE_JOHNSON), .N_FLOP_CROSS (2) ) u_rsp_cdc_fifo ( .axi_wr_aclk (gated_aclk), .axi_wr_aresetn (aresetn), .axi_rd_aclk (gated_pclk), .axi_rd_aresetn (presetn), .wr_valid (rsp_valid), .wr_ready (int_rsp_ready_aclk), .wr_data ({rsp_pslverr, rsp_prdata}), .rd_ready (w_rsp_ready), .rd_valid (w_rsp_valid), .rd_data ({w_rsp_pslverr, w_rsp_prdata}) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module apb4_slave_cdc_cg #(
    parameter int ADDR_WIDTH         = 32,
    parameter int DATA_WIDTH         = 32,
    parameter int STRB_WIDTH         = DATA_WIDTH / 8,
    parameter int PROT_WIDTH         = 3,
    parameter int DEPTH              = 2,
    // Async-FIFO pointer encoding, surfaced here rather than left to the FIFO's
    // own default: 0 = Gray (power-of-2 derived FIFO depth), 1 = Johnson.
    // DEPTH also feeds the wrapped slave's gaxi_skid_buffers (2..8 inclusive
    // guard); with Gray the floored max(DEPTH,4) must be a power of two, so
    // the legal set is {2,3,4,8} -- Johnson lifts 5, 6 and 7.
    // Defaults to 0. Johnson is opt-in and must be a conscious choice -- its
    // pointers are max(DEPTH,4) bits wide (the floored FIFO depth) against
    // Gray's $clog2(max(DEPTH,4))+1, duplicated
    // per domain and per synchronizer stage.
    parameter int USE_JOHNSON = 0,
    // Clock gating parameters
    parameter int CG_IDLE_COUNT_WIDTH = 4,  // Width of idle counter
    // CDC handshake variant: 1 = 2-phase (toggle, faster), 0 = 4-phase (level, classic)
    parameter bit USE_2_PHASE_CDC    = 1'b1,   // deprecated, ignored
    // Short Parameters
    parameter int DW  = DATA_WIDTH,
    parameter int AW  = ADDR_WIDTH,
    parameter int SW  = STRB_WIDTH,
    parameter int PW  = PROT_WIDTH,
    parameter int CPW = AW + DW + SW + PW + 1,
    parameter int RPW = DW + 1
) (
    // Clock and Reset
    input  logic              aclk,
    input  logic              aresetn,
    input  logic              pclk,
    input  logic              presetn,
    // Clock gating configuration
    input  logic                           cfg_cg_enable,
    input  logic [CG_IDLE_COUNT_WIDTH-1:0] cfg_cg_idle_count,
    // APB interface
    input  logic              s_apb_PSEL,
    input  logic              s_apb_PENABLE,
    output logic              s_apb_PREADY,
    input  logic [AW-1:0]     s_apb_PADDR,
    input  logic              s_apb_PWRITE,
    input  logic [DW-1:0]     s_apb_PWDATA,
    input  logic [SW-1:0]     s_apb_PSTRB,
    input  logic [PW-1:0]     s_apb_PPROT,
    output logic [DW-1:0]     s_apb_PRDATA,
    output logic              s_apb_PSLVERR,
    // Command Interface
    output logic              cmd_valid,
    input  logic              cmd_ready,
    output logic              cmd_pwrite,
    output logic [AW-1:0]     cmd_paddr,
    output logic [DW-1:0]     cmd_pwdata,
    output logic [SW-1:0]     cmd_pstrb,
    output logic [PW-1:0]     cmd_pprot,
    // Response Interface
    input  logic              rsp_valid,
    output logic              rsp_ready,
    input  logic [DW-1:0]     rsp_prdata,
    input  logic              rsp_pslverr,
    // Clock gating status
    output logic              pclk_cg_gating,
    output logic              pclk_cg_idle,
    output logic              aclk_cg_gating,
    output logic              aclk_cg_idle,
    // Canonical whole-module gating status. Every *_cg wrapper exposes
    // cg_gating/cg_idle; this module has TWO independent clock domains, so the
    // per-domain signals above stay -- they are not interchangeable, and each
    // masks only its own side's readys. The canonical pair is the aggregate:
    // the module is gated only when BOTH domains are, and idle only when both
    // are idle.
    output logic              cg_gating,
    output logic              cg_idle
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
