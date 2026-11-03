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

    wire [DATA_WIDTH-1:0]  s_awaddr_reg;
    wire [2:0]             s_awprot_reg;
    wire                   s_awvalid_reg;
    wire                   s_awready_reg;
    wire [DATA_WIDTH-1:0]  s_wdata_reg;
    wire [STRB_WIDTH-1:0]  s_wstrb_reg;
    wire                   s_wvalid_reg;
    wire                   s_wready_reg;
    wire [1:0]             s_bresp_reg;
    wire                   s_bvalid_reg;
    wire                   s_bready_reg;
    wire [DATA_WIDTH-1:0]  s_araddr_reg;
    wire [2:0]             s_arprot_reg;
    wire                   s_arvalid_reg;
    wire                   s_arready_reg;
    wire [DATA_WIDTH-1:0]  s_rdata_reg;
    wire [1:0]             s_rresp_reg;
    wire                   s_rvalid_reg;
    wire                   s_rready_reg;

    wire [DATA_WIDTH-1:0]  m_awaddr_reg;
    wire [2:0]             m_awprot_reg;
    wire                   m_awvalid_reg;
    wire                   m_awready_reg;
    wire [DATA_WIDTH-1:0]  m_wdata_reg;
    wire [STRB_WIDTH-1:0]  m_wstrb_reg;
    wire                   m_wvalid_reg;
    wire                   m_wready_reg;
    wire [1:0]             m_bresp_reg;
    wire                   m_bvalid_reg;
    wire                   m_bready_reg;
    wire [DATA_WIDTH-1:0]  m_araddr_reg;
    wire [2:0]             m_arprot_reg;
    wire                   m_arvalid_reg;
    wire                   m_arready_reg;
    wire [DATA_WIDTH-1:0]  m_rdata_reg;
    wire [1:0]             m_rresp_reg;
    wire                   m_rvalid_reg;
    wire                   m_rready_reg;

    reg  wire [DATA_WIDTH-1:0]  s_awaddr_ff;
    reg  wire [2:0]             s_awprot_ff;
    reg  wire                   s_awvalid_ff;
    reg  wire                   s_awready_ff;
    reg  wire [DATA_WIDTH-1:0]  s_wdata_ff;
    reg  wire [STRB_WIDTH-1:0]  s_wstrb_ff;
    reg  wire                   s_wvalid_ff;
    reg  wire                   s_wready_ff;
    reg  wire [1:0]             s_bresp_ff;
    reg  wire                   s_bvalid_ff;
    reg  wire                   s_bready_ff;
    reg  wire [DATA_WIDTH-1:0]  s_araddr_ff;
    reg  wire [2:0]             s_arprot_ff;
    reg  wire                   s_arvalid_ff;
    reg  wire                   s_arready_ff;
    reg  wire [DATA_WIDTH-1:0]  s_rdata_ff;
    reg  wire [1:0]             s_rresp_ff;
    reg  wire                   s_rvalid_ff;
    reg  wire                   s_rready_ff;

    reg  wire [DATA_WIDTH-1:0]  m_awaddr_ff;
    reg  wire [2:0]             m_awprot_ff;
    reg  wire                   m_awvalid_ff;
    reg  wire                   m_awready_ff;
    reg  wire [DATA_WIDTH-1:0]  m_wdata_ff;
    reg  wire [STRB_WIDTH-1:0]  m_wstrb_ff;
    reg  wire                   m_wvalid_ff;
    reg  wire                   m_wready_ff;
    reg  wire [1:0]             m_bresp_ff;
    reg  wire                   m_bvalid_ff;
    reg  wire                   m_bready_ff;
    reg  wire [DATA_WIDTH-1:0]  m_araddr_ff;
    reg  wire [2:0]             m_arprot_ff;
    reg  wire                   m_arvalid_ff;
    reg  wire                   m_arready_ff;
    reg  wire [DATA_WIDTH-1:0]  m_rdata_ff;
    reg  wire [1:0]             m_rresp_ff;
    reg  wire                   m_rvalid_ff;
    reg  wire                   m_rready_ff;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_awaddr_reg <= 0;
            s_awprot_reg <= 0;
            s_awvalid_reg <= 0;
            s_awready_reg <= 0;
            s_wdata_reg <= 0;
            s_wstrb_reg <= 0;
            s_wvalid_reg <= 0;
            s_wready_reg <= 0;
            s_bresp_reg <= 0;
            s_bvalid_reg <= 0;
            s_bready_reg <= 0;
            s_araddr_reg <= 0;
            s_arprot_reg <= 0;
            s_arvalid_reg <= 0;
            s_arready_reg <= 0;
            s_rdata_reg <= 0;
            s_rresp_reg <= 0;
            s_rvalid_reg <= 0;
            s_rready_reg <= 0;
        end else begin
            s_awaddr_reg <= s_axil_awaddr;
            s_awprot_reg <= s_axil_awprot;
            s_awvalid_reg <= s_axil_awvalid;
            s_awready_reg <= m_axil_awready;
            s_wdata_reg <= s_axil_wdata;
            s_wstrb_reg <= s_axil_wstrb;
            s_wvalid_reg <= s_axil_wvalid;
            s_wready_reg <= m_axil_wready;
            s_bresp_reg <= m_axil_bresp;
            s_bvalid_reg <= m_axil_bvalid;
            s_bready_reg <= s_axil_bready;
            s_araddr_reg <= s_axil_araddr;
            s_arprot_reg <= s_axil_arprot;
            s_arvalid_reg <= s_axil_arvalid;
            s_arready_reg <= m_axil_arready;
            s_rdata_reg <= m_axil_rdata;
            s_rresp_reg <= m_axil_rresp;
            s_rvalid_reg <= m_axil_rvalid;
            s_rready_reg <= s_axil_rready;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_awaddr_reg <= 0;
            m_awprot_reg <= 0;
            m_awvalid_reg <= 0;
            m_awready_reg <= 0;
            m_wdata_reg <= 0;
            m_wstrb_reg <= 0;
            m_wvalid_reg <= 0;
            m_wready_reg <= 0;
            m_bresp_reg <= 0;
            m_bvalid_reg <= 0;
            m_bready_reg <= 0;
            m_araddr_reg <= 0;
            m_arprot_reg <= 0;
            m_arvalid_reg <= 0;
            m_arready_reg <= 0;
            m_rdata_reg <= 0;
            m_rresp_reg <= 0;
            m_rvalid_reg <= 0;
            m_rready_reg <= 0;
        end else begin
            m_awaddr_reg <= s_awaddr_ff;
            m_awprot_reg <= s_awprot_ff;
            m_awvalid_reg <= s_awvalid_ff;
            m_awready_reg <= s_awready_ff;
            m_wdata_reg <= s_wdata_ff;
            m_wstrb_reg <= s_wstrb_ff;
            m_wvalid_reg <= s_wvalid_ff;
            m_wready_reg <= s_wready_ff;
            m_bresp_reg <= s_bresp_ff;
            m_bvalid_reg <= s_bvalid_ff;
            m_bready_reg <= s_bready_ff;
            m_araddr_reg <= s_araddr_ff;
            m_arprot_reg <= s_arprot_ff;
            m_arvalid_reg <= s_arvalid_ff;
            m_arready_reg <= s_arready_ff;
            m_rdata_reg <= s_rdata_ff;
            m_rresp_reg <= s_rresp_ff;
            m_rvalid_reg <= s_rvalid_ff;
            m_rready_reg <= s_rready_ff;
        end
    end

    assign s_axil_awaddr = m_awaddr_reg;
    assign s_axil_awprot = m_awprot_reg;
    assign s_axil_awvalid = m_awvalid_reg;
    assign s_axil_awready = m_awready_reg;
    assign s_axil_wdata = m_wdata_reg;
    assign s_axil_wstrb = m_wstrb_reg;
    assign s_axil_wvalid = m_wvalid_reg;
    assign s_axil_wready = m_wready_reg;
    assign s_axil_bresp = m_bresp_reg;
    assign s_axil_bvalid = m_bvalid_reg;
    assign s_axil_araddr = m_araddr_reg;
    assign s_axil_arprot = m_arprot_reg;
    assign s_axil_arvalid = m_arvalid_reg;
    assign s_axil_arready = m_arready_reg;
    assign s_axil_rdata = m_rdata_reg;
    assign s_axil_rresp = m_rresp_reg;
    assign s_axil_rvalid = m_rvalid_reg;
    assign s_axil_rready = m_rready_reg;

    assign m_axil_awaddr = s_awaddr_reg;
    assign m_axil_awprot = s_awprot_reg;
    assign m_axil_awvalid = s_awvalid_reg;
    assign m_axil_awready = s_awready_reg;
    assign m_axil_wdata = s_wdata_reg;
    assign m_axil_wstrb = s_wstrb_reg;
    assign m_axil_wvalid = s_wvalid_reg;
    assign m_axil_wready = s_wready_reg;
    assign m_axil_bresp = s_bresp_reg;
    assign m_axil_bvalid = s_bvalid_reg;
    assign m_axil_araddr = s_araddr_reg;
    assign m_axil_arprot = s_arprot_reg;
    assign m_axil_arvalid = s_arvalid_reg;
    assign m_axil_arready = s_arready_reg;
    assign m_axil_rdata = s_rdata_reg;
    assign m_axil_rresp = s_rresp_reg;
    assign m_axil_rvalid = s_rvalid_reg;
    assign m_axil_rready = s_rready_reg;

endmodule
