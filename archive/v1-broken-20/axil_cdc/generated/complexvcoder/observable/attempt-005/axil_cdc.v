module axil_cdc #(
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

    // AXI-Lite write address channel bridge
    axil_cdc_aw #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) aw_bridge (
        .clk(s_clk),
        .rst(s_rst),
        .awaddr(s_axil_awaddr),
        .awprot(s_axil_awprot),
        .awvalid(s_axil_awvalid),
        .awready(m_axil_awready)
    );

    // AXI-Lite write data channel bridge
    axil_cdc_w #(
        .DATA_WIDTH(DATA_WIDTH),
        .STRB_WIDTH(STRB_WIDTH)
    ) w_bridge (
        .clk(s_clk),
        .rst(s_rst),
        .wdata(s_axil_wdata),
        .wstrb(s_axil_wstrb),
        .wvalid(s_axil_wvalid),
        .wready(m_axil_wready)
    );

    // AXI-Lite write response channel bridge
    axil_cdc_b #(
        .DATA_WIDTH(DATA_WIDTH)
    ) b_bridge (
        .clk(m_clk),
        .rst(m_rst),
        .bresp(m_axil_bresp),
        .bvalid(m_axil_bvalid),
        .bready(s_axil_bready)
    );

    // AXI-Lite read address channel bridge
    axil_cdc_ar #(
        .DATA_WIDTH(ADDR_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) ar_bridge (
        .clk(s_clk),
        .rst(s_rst),
        .araddr(s_axil_araddr),
        .arprot(s_axil_arprot),
        .arvalid(s_axil_arvalid),
        .arready(m_axil_arready)
    );

    // AXI-Lite read data channel bridge
    axil_cdc_r #(
        .DATA_WIDTH(DATA_WIDTH),
        .STRB_WIDTH(STRB_WIDTH)
    ) r_bridge (
        .clk(m_clk),
        .rst(m_rst),
        .rdata(m_axil_rdata),
        .rresp(m_axil_rresp),
        .rvalid(m_axil_rvalid),
        .rready(s_axil_rready)
    );

endmodule
