Implement the SystemVerilog module `axi4_to_axil4`.

AXI4 Full to AXI4-Lite Protocol Converter

Functional contract and interface notes:

Module: axi4_to_axil4
Purpose: AXI4 Full to AXI4-Lite Protocol Converter
Description:
Converts AXI4 full protocol to AXI4-Lite by instantiating separate
read and write converters:
- axi4_to_axil4_rd: Handles AR and R channels with burst decomposition
- axi4_to_axil4_wr: Handles AW, W, and B channels with burst decomposition
This top-level wrapper provides a complete bidirectional converter
while maintaining single source of truth for conversion logic.
Key Features:
- Burst decomposition: Multi-beat bursts → multiple single transactions
- Single-beat traffic converts combinationally; bursts run a
3-state decomposition FSM with tracking registers. No skid
buffers -- add external ones if timing needs them.
- Protocol compliant: Full AXI4 slave, AXI4-Lite master
- Response aggregation: Collects responses and returns with original ID
- Modular design: Instantiates standalone read/write converters
Parameters:
AXI_ID_WIDTH: Transaction ID width on AXI4 side (1-16)
AXI_ADDR_WIDTH: Address bus width (12-64)
AXI_DATA_WIDTH: Data bus width - must match (32, 64, 128, 256)
AXI_USER_WIDTH: User signal width on AXI4 side (0-1024)
Limitations:
- Data widths must match (no data width conversion)
- Burst types: FIXED, INCR, WRAP all converted to single beats
- Assumes downstream AXI4-Lite slave can handle traffic rate
Modified: 2025-11-10 - Refactored to instantiate separate read/write modules

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
module axi4_to_axil4 #(
    // Width Configuration
    parameter int AXI_ID_WIDTH      = 8,
    parameter int AXI_ADDR_WIDTH    = 32,
    parameter int AXI_DATA_WIDTH    = 32,
    parameter int AXI_USER_WIDTH    = 1,
    // Skid Buffer Depths (for timing closure)
    // Calculated Parameters
    localparam int STRB_WIDTH = AXI_DATA_WIDTH / 8
) (
    // Clock and Reset
    input  logic                        aclk,
    input  logic                        aresetn,
    //==========================================================================
    // Slave AXI4 Interface (Input - Full Protocol)
    //==========================================================================
    // Read Address Channel
    input  logic [AXI_ID_WIDTH-1:0]     s_axi_arid,
    input  logic [AXI_ADDR_WIDTH-1:0]   s_axi_araddr,
    input  logic [7:0]                  s_axi_arlen,
    input  logic [2:0]                  s_axi_arsize,
    input  logic [1:0]                  s_axi_arburst,
    input  logic                        s_axi_arlock,
    input  logic [3:0]                  s_axi_arcache,
    input  logic [2:0]                  s_axi_arprot,
    input  logic [3:0]                  s_axi_arqos,
    input  logic [3:0]                  s_axi_arregion,
    input  logic [AXI_USER_WIDTH-1:0]   s_axi_aruser,
    input  logic                        s_axi_arvalid,
    output logic                        s_axi_arready,
    // Read Data Channel
    output logic [AXI_ID_WIDTH-1:0]     s_axi_rid,
    output logic [AXI_DATA_WIDTH-1:0]   s_axi_rdata,
    output logic [1:0]                  s_axi_rresp,
    output logic                        s_axi_rlast,
    output logic [AXI_USER_WIDTH-1:0]   s_axi_ruser,
    output logic                        s_axi_rvalid,
    input  logic                        s_axi_rready,
    // Write Address Channel
    input  logic [AXI_ID_WIDTH-1:0]     s_axi_awid,
    input  logic [AXI_ADDR_WIDTH-1:0]   s_axi_awaddr,
    input  logic [7:0]                  s_axi_awlen,
    input  logic [2:0]                  s_axi_awsize,
    input  logic [1:0]                  s_axi_awburst,
    input  logic                        s_axi_awlock,
    input  logic [3:0]                  s_axi_awcache,
    input  logic [2:0]                  s_axi_awprot,
    input  logic [3:0]                  s_axi_awqos,
    input  logic [3:0]                  s_axi_awregion,
    input  logic [AXI_USER_WIDTH-1:0]   s_axi_awuser,
    input  logic                        s_axi_awvalid,
    output logic                        s_axi_awready,
    // Write Data Channel
    input  logic [AXI_DATA_WIDTH-1:0]   s_axi_wdata,
    input  logic [STRB_WIDTH-1:0]       s_axi_wstrb,
    input  logic                        s_axi_wlast,
    input  logic [AXI_USER_WIDTH-1:0]   s_axi_wuser,
    input  logic                        s_axi_wvalid,
    output logic                        s_axi_wready,
    // Write Response Channel
    output logic [AXI_ID_WIDTH-1:0]     s_axi_bid,
    output logic [1:0]                  s_axi_bresp,
    output logic [AXI_USER_WIDTH-1:0]   s_axi_buser,
    output logic                        s_axi_bvalid,
    input  logic                        s_axi_bready,
    //==========================================================================
    // Master AXI4-Lite Interface (Output - Simplified Protocol)
    //==========================================================================
    // Read Address Channel
    output logic [AXI_ADDR_WIDTH-1:0]   m_axil_araddr,
    output logic [2:0]                  m_axil_arprot,
    output logic                        m_axil_arvalid,
    input  logic                        m_axil_arready,
    // Read Data Channel
    input  logic [AXI_DATA_WIDTH-1:0]   m_axil_rdata,
    input  logic [1:0]                  m_axil_rresp,
    input  logic                        m_axil_rvalid,
    output logic                        m_axil_rready,
    // Write Address Channel
    output logic [AXI_ADDR_WIDTH-1:0]   m_axil_awaddr,
    output logic [2:0]                  m_axil_awprot,
    output logic                        m_axil_awvalid,
    input  logic                        m_axil_awready,
    // Write Data Channel
    output logic [AXI_DATA_WIDTH-1:0]   m_axil_wdata,
    output logic [STRB_WIDTH-1:0]       m_axil_wstrb,
    output logic                        m_axil_wvalid,
    input  logic                        m_axil_wready,
    // Write Response Channel
    input  logic [1:0]                  m_axil_bresp,
    input  logic                        m_axil_bvalid,
    output logic                        m_axil_bready
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
