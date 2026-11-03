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

    wire [ADDR_WIDTH-1:0] m_axil_awaddr_reg;
    wire [2:0] m_axil_awprot_reg;
    wire m_axil_awvalid_reg;
    wire m_axil_wdata_reg;
    wire [STRB_WIDTH-1:0] m_axil_wstrb_reg;
    wire m_axil_wvalid_reg;
    wire m_axil_bready_reg;
    wire [ADDR_WIDTH-1:0] m_axil_araddr_reg;
    wire [2:0] m_axil_arprot_reg;
    wire m_axil_arvalid_reg;
    wire m_axil_rready_reg;

    wire [ADDR_WIDTH-1:0] s_axil_awaddr_reg;
    wire [2:0] s_axil_awprot_reg;
    wire s_axil_awvalid_reg;
    wire [DATA_WIDTH-1:0] s_axil_wdata_reg;
    wire [STRB_WIDTH-1:0] s_axil_wstrb_reg;
    wire s_axil_wvalid_reg;
    wire s_axil_bready_reg;
    wire [ADDR_WIDTH-1:0] s_axil_araddr_reg;
    wire [2:0] s_axil_arprot_reg;
    wire s_axil_arvalid_reg;
    wire s_axil_rready_reg;

    wire m_axil_awready;
    wire m_axil_wready;
    wire m_axil_bresp;
    wire m_axil_bvalid;
    wire m_axil_arready;
    wire [DATA_WIDTH-1:0] m_axil_rdata;
    wire m_axil_rresp;
    wire m_axil_rvalid;

    wire s_axil_awready;
    wire s_axil_wready;
    wire s_axil_bresp;
    wire s_axil_bvalid;
    wire s_axil_arready;
    wire [DATA_WIDTH-1:0] s_axil_rdata;
    wire s_axil_rresp;
    wire s_axil_rvalid;

    axil_cdc_master #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .STRB_WIDTH(STRB_WIDTH)
    ) m_axil (
        .clk(m_clk),
        .rst(m_rst),
        .awaddr(m_axil_awaddr),
        .awprot(m_axil_awprot),
        .awvalid(m_axil_awvalid),
        .awready(m_axil_awready),
        .wdata(m_axil_wdata),
        .wstrb(m_axil_wstrb),
        .wvalid(m_axil_wvalid),
        .wready(m_axil_wready),
        .bresp(m_axil_bresp),
        .bvalid(m_axil_bvalid),
        .bready(m_axil_bready),
        .araddr(m_axil_araddr),
        .arprot(m_axil_arprot),
        .arvalid(m_axil_arvalid),
        .arready(m_axil_arready),
        .rdata(m_axil_rdata),
        .rresp(m_axil_rresp),
        .rvalid(m_axil_rvalid),
        .rready(m_axil_rready),
        .awaddr_reg(m_axil_awaddr_reg),
        .awprot_reg(m_axil_awprot_reg),
        .awvalid_reg(m_axil_awvalid_reg),
        .wdata_reg(m_axil_wdata_reg),
        .wstrb_reg(m_axil_wstrb_reg),
        .wvalid_reg(m_axil_wvalid_reg),
        .bready_reg(m_axil_bready_reg),
        .araddr_reg(m_axil_araddr_reg),
        .arprot_reg(m_axil_arprot_reg),
        .arvalid_reg(m_axil_arvalid_reg),
        .rready_reg(m_axil_rready_reg)
    );

    axil_cdc_slave #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .STRB_WIDTH(STRB_WIDTH)
    ) s_axil (
        .clk(s_clk),
        .rst(s_rst),
        .awaddr(s_axil_awaddr),
        .awprot(s_axil_awprot),
        .awvalid(s_axil_awvalid),
        .awready(s_axil_awready),
        .wdata(s_axil_wdata),
        .wstrb(s_axil_wstrb),
        .wvalid(s_axil_wvalid),
        .wready(s_axil_wready),
        .bresp(s_axil_bresp),
        .bvalid(s_axil_bvalid),
        .bready(s_axil_bready),
        .araddr(s_axil_araddr),
        .arprot(s_axil_arprot),
        .arvalid(s_axil_arvalid),
        .arready(s_axil_arready),
        .rdata(s_axil_rdata),
        .rresp(s_axil_rresp),
        .rvalid(s_axil_rvalid),
        .rready(s_axil_rready),
        .awaddr_reg(m_axil_awaddr_reg),
        .awprot_reg(m_axil_awprot_reg),
        .awvalid_reg(m_axil_awvalid_reg),
        .wdata_reg(m_axil_wdata_reg),
        .wstrb_reg(m_axil_wstrb_reg),
        .wvalid_reg(m_axil_wvalid_reg),
        .bready_reg(m_axil_bready_reg),
        .araddr_reg(m_axil_araddr_reg),
        .arprot_reg(m_axil_arprot_reg),
        .arvalid_reg(m_axil_arvalid_reg),
        .rready_reg(m_axil_rready_reg)
    );

endmodule
