Implement the SystemVerilog module `uart_axil_bridge`.

UART to AXI4-Lite Master Bridge

Functional contract and interface notes:

Module: uart_axil_bridge
Purpose: UART to AXI4-Lite Master Bridge
Parses UART commands and executes AXI4-Lite transactions with timing isolation
Command Protocol:
Write: W <addr_hex> <data_hex>\n  -> Response: "OK\n"
Read:  R <addr_hex>\n             -> Response: "0xDEADBEEF\n"

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
module uart_axil_bridge #(
    parameter int AXIL_ADDR_WIDTH = 32,
    parameter int AXIL_DATA_WIDTH = 32,
    parameter int CLKS_PER_BIT    = 868,  // 100MHz / 115200 baud
    parameter int SKID_DEPTH_AR   = 2,
    parameter int SKID_DEPTH_R    = 4,
    parameter int SKID_DEPTH_AW   = 2,
    parameter int SKID_DEPTH_W    = 4,
    parameter int SKID_DEPTH_B    = 2
)(
    input  logic                         aclk,
    input  logic                         aresetn,
    // UART interface
    input  logic                         i_uart_rx,
    output logic                         o_uart_tx,
    // AXI4-Lite Master interface (with timing isolation)
    output logic [AXIL_ADDR_WIDTH-1:0]   m_axil_awaddr,
    output logic [2:0]                   m_axil_awprot,
    output logic                         m_axil_awvalid,
    input  logic                         m_axil_awready,
    output logic [AXIL_DATA_WIDTH-1:0]   m_axil_wdata,
    output logic [AXIL_DATA_WIDTH/8-1:0] m_axil_wstrb,
    output logic                         m_axil_wvalid,
    input  logic                         m_axil_wready,
    input  logic [1:0]                   m_axil_bresp,
    input  logic                         m_axil_bvalid,
    output logic                         m_axil_bready,
    output logic [AXIL_ADDR_WIDTH-1:0]   m_axil_araddr,
    output logic [2:0]                   m_axil_arprot,
    output logic                         m_axil_arvalid,
    input  logic                         m_axil_arready,
    input  logic [AXIL_DATA_WIDTH-1:0]   m_axil_rdata,
    input  logic [1:0]                   m_axil_rresp,
    input  logic                         m_axil_rvalid,
    output logic                         m_axil_rready
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
