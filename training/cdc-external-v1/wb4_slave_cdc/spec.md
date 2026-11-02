Implement the SystemVerilog module `wb4_slave_cdc`.

wb4_slave with its command and response queues carried across a

Functional contract and interface notes:

Module: wb4_slave_cdc
Purpose: wb4_slave with its command and response queues carried across a
clock-domain boundary: the Wishbone bus in wb_clk, the FUB
queues in aclk.
Description:
wb4_slave in the wb_clk domain, plus two gaxi_fifo_async instances:
cmd (wb_clk -> aclk) and rsp (aclk -> wb_clk). Same shape as
apb4_slave_cdc, whose reset analysis applies here unchanged: each FIFO
resets its own side's pointers from that side's reset, so a ONE-SIDED
reset while transfers are in the FIFOs is not safe (a write-side reset
alone lets the read side see phantom occupancy, a read-side reset alone
replays consumed entries). Quiesce the bus before resetting one side.
In-order termination is preserved: both FIFOs are FIFOs, so the n-th
response returned by the FUB terminates the n-th accepted request.
MAX_OUTSTANDING still bounds the requests the slave accepts while
responses are pending, so the response FIFO can never overflow the
slave's response queue.
Parameters:
wb4_slave's, plus
CDC_DEPTH   - async FIFO depth (floored at 4; power of two preferred)
USE_JOHNSON - 0 = Gray pointers (power-of-two depth), 1 = Johnson

Required clock and reset behavior:

- Clock ports: wb_clk, aclk.
- Reset ports: wb_resetn, aresetn.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- gaxi_fifo_async: gaxi_fifo_async #( .DATA_WIDTH (CPW), .DEPTH (CDC_FIFO_DEPTH), .USE_JOHNSON (USE_JOHNSON), .N_FLOP_CROSS (2) ) u_cmd_cdc_fifo ( .axi_wr_aclk (wb_clk), .axi_wr_aresetn (wb_resetn), .axi_rd_aclk (aclk), .axi_rd_aresetn (aresetn), .wr_valid (w_cmd_valid), .wr_ready (w_cmd_ready), .wr_data (w_cmd_cdc_in), .rd_ready (cmd_ready), .rd_valid (cmd_valid), .rd_data (w_cmd_cdc_out) );
- gaxi_fifo_async: gaxi_fifo_async #( .DATA_WIDTH (RPW), .DEPTH (CDC_FIFO_DEPTH), .USE_JOHNSON (USE_JOHNSON), .N_FLOP_CROSS (2) ) u_rsp_cdc_fifo ( .axi_wr_aclk (aclk), .axi_wr_aresetn (aresetn), .axi_rd_aclk (wb_clk), .axi_rd_aresetn (wb_resetn), .wr_valid (rsp_valid), .wr_ready (rsp_ready), .wr_data ({rsp_status, rsp_dat}), .rd_ready (w_rsp_ready), .rd_valid (w_rsp_valid), .rd_data ({w_rsp_status, w_rsp_dat}) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module wb4_slave_cdc
    import wb4_pkg::*;
#(
    parameter int ADDR_WIDTH      = 32,
    parameter int DATA_WIDTH      = 32,
    parameter int CMD_DEPTH       = 2,
    parameter int RSP_DEPTH       = 2,
    parameter int USE_BURST_HINTS = 0,   // see wb4_master/wb4_slave
    parameter int MAX_OUTSTANDING = 16,
    parameter int CLASSIC         = 0,
    parameter int CDC_DEPTH       = 4,
    parameter int USE_JOHNSON     = 0,
    parameter int SEL_WIDTH       = DATA_WIDTH / 8,
    // Short params
    parameter int AW  = ADDR_WIDTH,
    parameter int DW  = DATA_WIDTH,
    parameter int SW  = SEL_WIDTH,
    parameter int STW = WB4_STATUS_WIDTH,
    parameter int CTW = wb4_pkg::WB4_CTI_WIDTH,
    parameter int BTW = wb4_pkg::WB4_BTE_WIDTH,
    // {we, adr, dat, sel} plus the hints when carried: a burst hint that
    // did not cross with its own transfer would describe the wrong one.
    parameter int CPW = 1 + AW + DW + SW + ((USE_BURST_HINTS != 0) ? CTW + BTW : 0),
    parameter int RPW = STW + DW            // {status, dat}
)
(
    // Wishbone domain
    input  logic              wb_clk,
    input  logic              wb_resetn,
    // FUB domain
    input  logic              aclk,
    input  logic              aresetn,
    // Wishbone B4 slave (wb_clk)
    input  logic              s_wb_CYC,
    input  logic              s_wb_STB,
    input  logic              s_wb_WE,
    input  logic [AW-1:0]     s_wb_ADR,
    input  logic [DW-1:0]     s_wb_DAT_W,
    input  logic [SW-1:0]     s_wb_SEL,
    input  logic [CTW-1:0]    s_wb_CTI,
    input  logic [BTW-1:0]    s_wb_BTE,
    output logic              s_wb_STALL,
    output logic              s_wb_ACK,
    output logic              s_wb_ERR,
    output logic              s_wb_RTY,
    output logic [DW-1:0]     s_wb_DAT_R,
    // Command queue (aclk)
    output logic              cmd_valid,
    input  logic              cmd_ready,
    output logic              cmd_we,
    output logic [AW-1:0]     cmd_adr,
    output logic [DW-1:0]     cmd_dat,
    output logic [SW-1:0]     cmd_sel,
    output logic [CTW-1:0]    cmd_cti,
    output logic [BTW-1:0]    cmd_bte,
    // Response queue (aclk)
    input  logic              rsp_valid,
    output logic              rsp_ready,
    input  logic [STW-1:0]    rsp_status,
    input  logic [DW-1:0]     rsp_dat,
    // Activity in the WB_CLK domain only: a cycle open on the bus, a command
    // waiting to cross, or a response that has crossed and not yet been
    // driven. The clock-gated variant wakes on this; nothing in the aclk
    // domain may be used for that, because sampling it in wb_clk would be an
    // unsynchronised crossing.
    output logic              wb_busy
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
