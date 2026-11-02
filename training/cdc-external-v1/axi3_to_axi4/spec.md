Implement the SystemVerilog module `axi3_to_axi4`.

AXI3 Full to AXI4 Protocol Converter (top wrapper)

Functional contract and interface notes:

Module: axi3_to_axi4
Purpose: AXI3 Full to AXI4 Protocol Converter (top wrapper)
Description:
Top-level wrapper that combines the standalone read and write AXI3->AXI4
converters into a complete bidirectional converter:
- axi3_to_axi4_rd: handles AR and R channels with ARLEN zero-extension and
ARLOCK mapping
- axi3_to_axi4_wr: handles AW, W, and B channels with AWLEN zero-extension,
AWLOCK mapping, and WID stripping under a single-active-write contract
This module exposes the union of both submodule port lists: a full AXI3
slave interface and a full AXI4 master interface.
Key Features:
- Modular design: instantiates standalone read/write converters
- Full 5-channel AXI3 slave and AXI4 master port sets
- Single source of truth for read/write conversion logic
Parameters:
AXI_ID_WIDTH: Transaction ID width on AXI3/AXI4 side (1-16)
AXI_ADDR_WIDTH: Address bus width (12-64)
AXI_DATA_WIDTH: Data bus width - must match (32, 64, 128, 256)
AXI_USER_WIDTH: User signal width on AXI3/AXI4 side (0-1024)
Limitations:
- Data widths must match (no data width conversion)
- One outstanding write transaction at a time

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
module axi3_to_axi4 #(
    // Width Configuration
    parameter int AXI_ID_WIDTH      = 8,
    parameter int AXI_ADDR_WIDTH    = 32,
    parameter int AXI_DATA_WIDTH    = 32,
    parameter int AXI_USER_WIDTH    = 1,
    // Calculated Parameters
    localparam int STRB_WIDTH = AXI_DATA_WIDTH / 8
) (
    // Clock and Reset
    input  logic                        aclk,
    input  logic                        aresetn,
    //==========================================================================
    // Slave AXI3 Interface (Input - AXI3 Protocol)
    //==========================================================================
    // Read Address Channel
    input  logic [AXI_ID_WIDTH-1:0]     s_axi3_arid,
    input  logic [AXI_ADDR_WIDTH-1:0]   s_axi3_araddr,
    input  logic [3:0]                  s_axi3_arlen,
    input  logic [2:0]                  s_axi3_arsize,
    input  logic [1:0]                  s_axi3_arburst,
    input  logic [1:0]                  s_axi3_arlock,
    input  logic [3:0]                  s_axi3_arcache,
    input  logic [2:0]                  s_axi3_arprot,
    input  logic [AXI_USER_WIDTH-1:0]   s_axi3_aruser,
    input  logic                        s_axi3_arvalid,
    output logic                        s_axi3_arready,
    // Read Data Channel
    output logic [AXI_ID_WIDTH-1:0]     s_axi3_rid,
    output logic [AXI_DATA_WIDTH-1:0]   s_axi3_rdata,
    output logic [1:0]                  s_axi3_rresp,
    output logic                        s_axi3_rlast,
    output logic [AXI_USER_WIDTH-1:0]   s_axi3_ruser,
    output logic                        s_axi3_rvalid,
    input  logic                        s_axi3_rready,
    // Write Address Channel
    input  logic [AXI_ID_WIDTH-1:0]     s_axi3_awid,
    input  logic [AXI_ADDR_WIDTH-1:0]   s_axi3_awaddr,
    input  logic [3:0]                  s_axi3_awlen,
    input  logic [2:0]                  s_axi3_awsize,
    input  logic [1:0]                  s_axi3_awburst,
    input  logic [1:0]                  s_axi3_awlock,
    input  logic [3:0]                  s_axi3_awcache,
    input  logic [2:0]                  s_axi3_awprot,
    input  logic [AXI_USER_WIDTH-1:0]   s_axi3_awuser,
    input  logic                        s_axi3_awvalid,
    output logic                        s_axi3_awready,
    // Write Data Channel
    input  logic [AXI_ID_WIDTH-1:0]     s_axi3_wid,
    input  logic [AXI_DATA_WIDTH-1:0]   s_axi3_wdata,
    input  logic [STRB_WIDTH-1:0]       s_axi3_wstrb,
    input  logic                        s_axi3_wlast,
    input  logic [AXI_USER_WIDTH-1:0]   s_axi3_wuser,
    input  logic                        s_axi3_wvalid,
    output logic                        s_axi3_wready,
    // Write Response Channel
    output logic [AXI_ID_WIDTH-1:0]     s_axi3_bid,
    output logic [1:0]                  s_axi3_bresp,
    output logic [AXI_USER_WIDTH-1:0]   s_axi3_buser,
    output logic                        s_axi3_bvalid,
    input  logic                        s_axi3_bready,
    //==========================================================================
    // Master AXI4 Interface (Output - Full Protocol)
    //==========================================================================
    // Read Address Channel
    output logic [AXI_ID_WIDTH-1:0]     m_axi_arid,
    output logic [AXI_ADDR_WIDTH-1:0]   m_axi_araddr,
    output logic [7:0]                  m_axi_arlen,
    output logic [2:0]                  m_axi_arsize,
    output logic [1:0]                  m_axi_arburst,
    output logic                        m_axi_arlock,
    output logic [3:0]                  m_axi_arcache,
    output logic [2:0]                  m_axi_arprot,
    output logic [3:0]                  m_axi_arqos,
    output logic [3:0]                  m_axi_arregion,
    output logic [AXI_USER_WIDTH-1:0]   m_axi_aruser,
    output logic                        m_axi_arvalid,
    input  logic                        m_axi_arready,
    // Read Data Channel
    input  logic [AXI_ID_WIDTH-1:0]     m_axi_rid,
    input  logic [AXI_DATA_WIDTH-1:0]   m_axi_rdata,
    input  logic [1:0]                  m_axi_rresp,
    input  logic                        m_axi_rlast,
    input  logic [AXI_USER_WIDTH-1:0]   m_axi_ruser,
    input  logic                        m_axi_rvalid,
    output logic                        m_axi_rready,
    // Write Address Channel
    output logic [AXI_ID_WIDTH-1:0]     m_axi_awid,
    output logic [AXI_ADDR_WIDTH-1:0]   m_axi_awaddr,
    output logic [7:0]                  m_axi_awlen,
    output logic [2:0]                  m_axi_awsize,
    output logic [1:0]                  m_axi_awburst,
    output logic                        m_axi_awlock,
    output logic [3:0]                  m_axi_awcache,
    output logic [2:0]                  m_axi_awprot,
    output logic [3:0]                  m_axi_awqos,
    output logic [3:0]                  m_axi_awregion,
    output logic [AXI_USER_WIDTH-1:0]   m_axi_awuser,
    output logic                        m_axi_awvalid,
    input  logic                        m_axi_awready,
    // Write Data Channel
    output logic [AXI_DATA_WIDTH-1:0]   m_axi_wdata,
    output logic [STRB_WIDTH-1:0]       m_axi_wstrb,
    output logic                        m_axi_wlast,
    output logic [AXI_USER_WIDTH-1:0]   m_axi_wuser,
    output logic                        m_axi_wvalid,
    input  logic                        m_axi_wready,
    // Write Response Channel
    input  logic [AXI_ID_WIDTH-1:0]     m_axi_bid,
    input  logic [1:0]                  m_axi_bresp,
    input  logic [AXI_USER_WIDTH-1:0]   m_axi_buser,
    input  logic                        m_axi_bvalid,
    output logic                        m_axi_bready
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
