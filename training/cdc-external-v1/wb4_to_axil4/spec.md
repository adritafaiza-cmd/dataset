Implement the SystemVerilog module `wb4_to_axil4`.

Wishbone B4 slave in, AXI4-Lite master out.

Functional contract and interface notes:

Module: wb4_to_axil4
Purpose: Wishbone B4 slave in, AXI4-Lite master out.
Description:
wb4_slave (Wishbone bus to command/response queues)
-> wb4_to_axil4_core (queues to the five AXI4-Lite channels, merging the
two response channels back into one in-order termination stream)
-> axil4_master_wr + axil4_master_rd (channels to the bus).
The mirror of axil4_to_wb4. Same address and data width on both sides.
Parameters:
ADDR_WIDTH, DATA_WIDTH
CMD_DEPTH, RSP_DEPTH, MAX_OUTSTANDING - the wb4_slave's queues and bound
CLASSIC          - 0 = B4 pipelined, 1 = B4 standard; match the master
OUTSTANDING      - commands in flight through the core (1 = serialised)
SKID_DEPTH_*     - the AXI4-Lite masters' channel skids
AXIL_PROT        - AWPROT/ARPROT driven on every command
Test:
Location: projects/components/utility-ip/converters/dv/tests/test_wb4_to_axil4.py

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
module wb4_to_axil4
    import wb4_pkg::*;
#(
    parameter int ADDR_WIDTH      = 32,
    parameter int DATA_WIDTH      = 32,
    parameter int CMD_DEPTH       = 2,
    parameter int RSP_DEPTH       = 2,
    parameter int MAX_OUTSTANDING = 16,
    parameter int CLASSIC         = 0,
    parameter int OUTSTANDING     = 1,
    parameter int SKID_DEPTH_AW   = 2,
    parameter int SKID_DEPTH_W    = 2,
    parameter int SKID_DEPTH_B    = 2,
    parameter int SKID_DEPTH_AR   = 2,
    parameter int SKID_DEPTH_R    = 2,
    parameter logic [2:0] AXIL_PROT = 3'b000,
    // Short params
    parameter int AW  = ADDR_WIDTH,
    parameter int DW  = DATA_WIDTH,
    parameter int SW  = DW/8,
    parameter int CTW = WB4_CTI_WIDTH,
    parameter int BTW = WB4_BTE_WIDTH
)
(
    input  logic              aclk,
    input  logic              aresetn,
    // Wishbone B4 slave
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
    // AXI4-Lite master
    output logic [AW-1:0]     m_axil_awaddr,
    output logic [2:0]        m_axil_awprot,
    output logic              m_axil_awvalid,
    input  logic              m_axil_awready,
    output logic [DW-1:0]     m_axil_wdata,
    output logic [SW-1:0]     m_axil_wstrb,
    output logic              m_axil_wvalid,
    input  logic              m_axil_wready,
    input  logic [1:0]        m_axil_bresp,
    input  logic              m_axil_bvalid,
    output logic              m_axil_bready,
    output logic [AW-1:0]     m_axil_araddr,
    output logic [2:0]        m_axil_arprot,
    output logic              m_axil_arvalid,
    input  logic              m_axil_arready,
    input  logic [DW-1:0]     m_axil_rdata,
    input  logic [1:0]        m_axil_rresp,
    input  logic              m_axil_rvalid,
    output logic              m_axil_rready,
    output logic              busy
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
