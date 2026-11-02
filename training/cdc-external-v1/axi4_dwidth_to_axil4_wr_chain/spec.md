Implement the SystemVerilog module `axi4_dwidth_to_axil4_wr_chain`.

FUB-level chain wrapping axi4_dwidth_converter_wr (downsize)

Functional contract and interface notes:

Module: axi4_dwidth_to_axil4_wr_chain
Purpose: FUB-level chain wrapping axi4_dwidth_converter_wr (downsize)
directly connected to axi4_to_axil4_wr.
Description:
Slave side: wide AXI4 (S_AXI_DATA_WIDTH).
axi4_dwidth_converter_wr downsizes the W beats to M_AXIL_DATA_WIDTH
and rewrites awlen/awsize so the downstream module sees a narrow
AXI4 burst of M_AXIL_DATA_WIDTH-wide beats.
axi4_to_axil4_wr then decomposes that narrow AXI4 burst into
single-beat AXIL4 writes on the master AXIL interface.
This chain is what real bridges instantiate when a wide master writes
to a narrow AXIL4 slave. It is the configuration that surfaces the
page-probe class of back-to-back boundary bugs at the bridge level,
so we exercise it at the FUB level here.
Parameters:
S_AXI_DATA_WIDTH   - Slave wide AXI4 data width (must be > M_AXIL)
M_AXIL_DATA_WIDTH  - Master AXIL4 data width (narrow)
AXI_ID_WIDTH       - AXI4 ID width (fixed at 8 by convention)
AXI_ADDR_WIDTH     - Address width

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
module axi4_dwidth_to_axil4_wr_chain #(
    parameter int S_AXI_DATA_WIDTH  = 64,
    parameter int M_AXIL_DATA_WIDTH = 32,
    parameter int AXI_ID_WIDTH      = 8,
    parameter int AXI_ADDR_WIDTH    = 32,
    parameter int AXI_USER_WIDTH    = 1,
    // Calculated
    localparam int S_STRB_WIDTH = S_AXI_DATA_WIDTH / 8,
    localparam int M_STRB_WIDTH = M_AXIL_DATA_WIDTH / 8
) (
    // Clock and Reset
    input  logic                          aclk,
    input  logic                          aresetn,
    //==========================================================================
    // Slave AXI4 Write Interface (wide)
    //==========================================================================
    input  logic [AXI_ID_WIDTH-1:0]       s_axi_awid,
    input  logic [AXI_ADDR_WIDTH-1:0]     s_axi_awaddr,
    input  logic [7:0]                    s_axi_awlen,
    input  logic [2:0]                    s_axi_awsize,
    input  logic [1:0]                    s_axi_awburst,
    input  logic                          s_axi_awlock,
    input  logic [3:0]                    s_axi_awcache,
    input  logic [2:0]                    s_axi_awprot,
    input  logic [3:0]                    s_axi_awqos,
    input  logic [3:0]                    s_axi_awregion,
    input  logic [AXI_USER_WIDTH-1:0]     s_axi_awuser,
    input  logic                          s_axi_awvalid,
    output logic                          s_axi_awready,
    input  logic [S_AXI_DATA_WIDTH-1:0]   s_axi_wdata,
    input  logic [S_STRB_WIDTH-1:0]       s_axi_wstrb,
    input  logic                          s_axi_wlast,
    input  logic [AXI_USER_WIDTH-1:0]     s_axi_wuser,
    input  logic                          s_axi_wvalid,
    output logic                          s_axi_wready,
    output logic [AXI_ID_WIDTH-1:0]       s_axi_bid,
    output logic [1:0]                    s_axi_bresp,
    output logic [AXI_USER_WIDTH-1:0]     s_axi_buser,
    output logic                          s_axi_bvalid,
    input  logic                          s_axi_bready,
    //==========================================================================
    // Master AXIL4 Write Interface (narrow)
    //==========================================================================
    output logic [AXI_ADDR_WIDTH-1:0]     m_axil_awaddr,
    output logic [2:0]                    m_axil_awprot,
    output logic                          m_axil_awvalid,
    input  logic                          m_axil_awready,
    output logic [M_AXIL_DATA_WIDTH-1:0]  m_axil_wdata,
    output logic [M_STRB_WIDTH-1:0]       m_axil_wstrb,
    output logic                          m_axil_wvalid,
    input  logic                          m_axil_wready,
    input  logic [1:0]                    m_axil_bresp,
    input  logic                          m_axil_bvalid,
    output logic                          m_axil_bready
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
