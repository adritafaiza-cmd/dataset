Please act as a professional Verilog designer.

Implement an AXI4-Lite clock-domain bridge.

Module name:
    axil_cdc

Language:
    Verilog-2001

Clocks:
    s_clk: Independent asynchronous clock (async to m_clk).
    m_clk: Independent asynchronous clock (async to s_clk).

Resets:
    s_rst: active-high.
    m_rst: active-high.

Input ports:
    s_clk: Clock.
    s_rst: Active-high reset.
    s_axil_awaddr: Address.
    s_axil_awprot: Protection bits.
    s_axil_awvalid: Handshake valid.
    s_axil_wdata: Data payload.
    s_axil_wstrb: Write strobes.
    s_axil_wvalid: Handshake valid.
    s_axil_bready: Handshake ready.
    s_axil_araddr: Address.
    s_axil_arprot: Protection bits.
    s_axil_arvalid: Handshake valid.
    s_axil_rready: Handshake ready.
    m_clk: Clock.
    m_rst: Active-high reset.
    m_axil_awready: Handshake ready.
    m_axil_wready: Handshake ready.
    m_axil_bresp: Response status.
    m_axil_bvalid: Handshake valid.
    m_axil_arready: Handshake ready.
    m_axil_rdata: Data payload.
    m_axil_rresp: Response status.
    m_axil_rvalid: Handshake valid.

Output ports:
    s_axil_awready: Handshake ready.
    s_axil_wready: Handshake ready.
    s_axil_bresp: Response status.
    s_axil_bvalid: Handshake valid.
    s_axil_arready: Handshake ready.
    s_axil_rdata: Data payload.
    s_axil_rresp: Response status.
    s_axil_rvalid: Handshake valid.
    m_axil_awaddr: Address.
    m_axil_awprot: Protection bits.
    m_axil_awvalid: Handshake valid.
    m_axil_wdata: Data payload.
    m_axil_wstrb: Write strobes.
    m_axil_wvalid: Handshake valid.
    m_axil_bready: Handshake ready.
    m_axil_araddr: Address.
    m_axil_arprot: Protection bits.
    m_axil_arvalid: Handshake valid.
    m_axil_rready: Handshake ready.

Parameters:
    DATA_WIDTH: Data width in bits.
    ADDR_WIDTH: Address or pointer width.
    STRB_WIDTH: See Behavior.

Behavior:
    - Accept AXI4-Lite write and read channels on the slave ports.
    - Forward each accepted transaction exactly once to the master ports.
    - Return bresp/rdata/rresp without loss, duplication, or reordering.
    - One outstanding write and one outstanding read are enough.
    - Reset must idle both interfaces and must not create a transaction.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module axil_cdc #
(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = (DATA_WIDTH/8)
)
(
    /*
     * AXI lite slave interface
     */
    input  wire                   s_clk,
    input  wire                   s_rst,
    input  wire [ADDR_WIDTH-1:0]  s_axil_awaddr,
    input  wire [2:0]             s_axil_awprot,
    input  wire                   s_axil_awvalid,
    output wire                   s_axil_awready,
    input  wire [DATA_WIDTH-1:0]  s_axil_wdata,
    input  wire [STRB_WIDTH-1:0]  s_axil_wstrb,
    input  wire                   s_axil_wvalid,
    output wire                   s_axil_wready,
    output wire [1:0]             s_axil_bresp,
    output wire                   s_axil_bvalid,
    input  wire                   s_axil_bready,
    input  wire [ADDR_WIDTH-1:0]  s_axil_araddr,
    input  wire [2:0]             s_axil_arprot,
    input  wire                   s_axil_arvalid,
    output wire                   s_axil_arready,
    output wire [DATA_WIDTH-1:0]  s_axil_rdata,
    output wire [1:0]             s_axil_rresp,
    output wire                   s_axil_rvalid,
    input  wire                   s_axil_rready,
    /*
     * AXI lite master interface
     */
    input  wire                   m_clk,
    input  wire                   m_rst,
    output wire [ADDR_WIDTH-1:0]  m_axil_awaddr,
    output wire [2:0]             m_axil_awprot,
    output wire                   m_axil_awvalid,
    input  wire                   m_axil_awready,
    output wire [DATA_WIDTH-1:0]  m_axil_wdata,
    output wire [STRB_WIDTH-1:0]  m_axil_wstrb,
    output wire                   m_axil_wvalid,
    input  wire                   m_axil_wready,
    input  wire [1:0]             m_axil_bresp,
    input  wire                   m_axil_bvalid,
    output wire                   m_axil_bready,
    output wire [ADDR_WIDTH-1:0]  m_axil_araddr,
    output wire [2:0]             m_axil_arprot,
    output wire                   m_axil_arvalid,
    input  wire                   m_axil_arready,
    input  wire [DATA_WIDTH-1:0]  m_axil_rdata,
    input  wire [1:0]             m_axil_rresp,
    input  wire                   m_axil_rvalid,
    output wire                   m_axil_rready
);
