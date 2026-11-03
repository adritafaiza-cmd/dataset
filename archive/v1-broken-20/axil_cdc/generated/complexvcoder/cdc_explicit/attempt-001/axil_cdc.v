module axil_cdc #
(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = (DATA_WIDTH/8)
)
(
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

    wire [ADDR_WIDTH-1:0] slave_awaddr;
    wire [2:0] slave_awprot;
    wire slave_awvalid;
    wire slave_awready;
    wire [DATA_WIDTH-1:0] slave_wdata;
    wire [STRB_WIDTH-1:0] slave_wstrb;
    wire slave_wvalid;
    wire slave_wready;
    wire [1:0] slave_bresp;
    wire slave_bvalid;
    wire slave_bready;
    wire [ADDR_WIDTH-1:0] slave_araddr;
    wire [2:0] slave_arprot;
    wire slave_arvalid;
    wire slave_arready;
    wire [DATA_WIDTH-1:0] slave_rdata;
    wire [1:0] slave_rresp;
    wire slave_rvalid;
    wire slave_rready;

    axil_slave #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .STRB_WIDTH(STRB_WIDTH)
    ) slave (
        .clk(s_clk),
        .rst(s_rst),
        .awaddr(s_axil_awaddr),
        .awprot(s_axil_awprot),
        .awvalid(s_axil_awvalid),
        .awready(slave_awready),
        .wdata(s_axil_wdata),
        .wstrb(s_axil_wstrb),
        .wvalid(s_axil_wvalid),
        .wready(slave_wready),
        .bresp(slave_bresp),
        .bvalid(slave_bvalid),
        .bready(s_axil_bready),
        .araddr(s_axil_araddr),
        .arprot(s_axil_arprot),
        .arvalid(s_axil_arvalid),
        .arready(slave_arready),
        .rdata(slave_rdata),
        .rresp(slave_rresp),
        .rvalid(slave_rvalid),
        .rready(s_axil_rready)
    );

    axil_master #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .STRB_WIDTH(STRB_WIDTH)
    ) master (
        .clk(m_clk),
        .rst(m_rst),
        .awaddr(slave_awaddr),
        .awprot(slave_awprot),
        .awvalid(slave_awvalid),
        .awready(s_axil_awready),
        .wdata(slave_wdata),
        .wstrb(slave_wstrb),
        .wvalid(slave_wvalid),
        .wready(s_axil_wready),
        .bresp(s_axil_bresp),
        .bvalid(s_axil_bvalid),
        .bready(slave_bready),
        .araddr(slave_araddr),
        .arprot(slave_arprot),
        .arvalid(slave_arvalid),
        .arready(s_axil_arready),
        .rdata(s_axil_rdata),
        .rresp(s_axil_rresp),
        .rvalid(s_axil_rvalid),
        .rready(slave_rready)
    );

endmodule
