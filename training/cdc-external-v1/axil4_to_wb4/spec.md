Implement the SystemVerilog module `axil4_to_wb4`.

AXI4-Lite slave in, Wishbone B4 master out.

Functional contract and interface notes:

Module: axil4_to_wb4
Purpose: AXI4-Lite slave in, Wishbone B4 master out.
Description:
axil4_slave_wr + axil4_slave_rd (skid buffers on every AXI4-Lite channel)
-> axil4_to_wb4_core (channel set to command/response queues)
-> wb4_master (queues to the Wishbone bus, pipelined or classic).
Same address and data width on both sides; no width conversion.
Parameters:
ADDR_WIDTH, DATA_WIDTH
SKID_DEPTH_AW/W/B/AR/R  - AXI4-Lite side skid depths (2..8)
CMD_DEPTH, RSP_DEPTH     - wb4_master queue depths; RSP_DEPTH bounds
the transfers on the bus
SIDE_DEPTH               - core direction queue (>= CMD_DEPTH + RSP_DEPTH)
CLASSIC                  - 0 = B4 pipelined, 1 = B4 standard (classic)
RTY_RESP                 - AXI response for a Wishbone RTY (SLVERR)
Test:
Location: projects/components/utility-ip/converters/dv/tests/test_axil4_to_wb4.py

Required clock and reset behavior:

- Clock ports: aclk.
- Reset ports: aresetn.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- reset_sync: reset_sync #( .N (3), .KEEP_ATTRS (1'b1), .IN_ACTIVE_LOW (1'b1), .OUT_ACTIVE_LOW(1'b1), .ASYNC_ASSERT (1'b1) ) u_reset_sync ( .clk (aclk), .rst_n (aresetn), .sync_rst_n (w_aresetn) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module axil4_to_wb4 #(
    parameter int ADDR_WIDTH    = 32,
    parameter int DATA_WIDTH    = 32,
    parameter int SKID_DEPTH_AW = 2,
    parameter int SKID_DEPTH_W  = 2,
    parameter int SKID_DEPTH_B  = 2,
    parameter int SKID_DEPTH_AR = 2,
    parameter int SKID_DEPTH_R  = 2,
    parameter int CMD_DEPTH     = 4,
    parameter int RSP_DEPTH     = 4,
    parameter int SIDE_DEPTH    = 8,
    parameter int CLASSIC       = 0,
    parameter logic [1:0] RTY_RESP = 2'b10,
    // Short params
    parameter int AW = ADDR_WIDTH,
    parameter int DW = DATA_WIDTH,
    parameter int SW = DW/8
)
(
    input  logic              aclk,
    input  logic              aresetn,
    // AXI4-Lite slave
    input  logic [AW-1:0]     s_axil_awaddr,
    input  logic [2:0]        s_axil_awprot,
    input  logic              s_axil_awvalid,
    output logic              s_axil_awready,
    input  logic [DW-1:0]     s_axil_wdata,
    input  logic [SW-1:0]     s_axil_wstrb,
    input  logic              s_axil_wvalid,
    output logic              s_axil_wready,
    output logic [1:0]        s_axil_bresp,
    output logic              s_axil_bvalid,
    input  logic              s_axil_bready,
    input  logic [AW-1:0]     s_axil_araddr,
    input  logic [2:0]        s_axil_arprot,
    input  logic              s_axil_arvalid,
    output logic              s_axil_arready,
    output logic [DW-1:0]     s_axil_rdata,
    output logic [1:0]        s_axil_rresp,
    output logic              s_axil_rvalid,
    input  logic              s_axil_rready,
    // Wishbone B4 master
    output logic              m_wb_CYC,
    output logic              m_wb_STB,
    output logic              m_wb_WE,
    output logic [AW-1:0]     m_wb_ADR,
    output logic [DW-1:0]     m_wb_DAT_W,
    output logic [SW-1:0]     m_wb_SEL,
    output logic [wb4_pkg::WB4_CTI_WIDTH-1:0] m_wb_CTI,
    output logic [wb4_pkg::WB4_BTE_WIDTH-1:0] m_wb_BTE,
    input  logic              m_wb_STALL,
    input  logic              m_wb_ACK,
    input  logic              m_wb_ERR,
    input  logic              m_wb_RTY,
    input  logic [DW-1:0]     m_wb_DAT_R,
    output logic              busy
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
