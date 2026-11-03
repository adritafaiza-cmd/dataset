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

    wire [DATA_WIDTH-1:0] s_axil_awaddr_reg;
    wire [2:0] s_axil_awprot_reg;
    wire s_axil_awvalid_reg;
    wire [DATA_WIDTH-1:0] s_axil_wdata_reg;
    wire [STRB_WIDTH-1:0] s_axil_wstrb_reg;
    wire s_axil_wvalid_reg;
    wire [DATA_WIDTH-1:0] m_axil_awaddr_reg;
    wire [2:0] m_axil_awprot_reg;
    wire m_axil_awvalid_reg;
    wire [DATA_WIDTH-1:0] m_axil_wdata_reg;
    wire [STRB_WIDTH-1:0] m_axil_wstrb_reg;
    wire m_axil_wvalid_reg;
    wire [1:0] m_axil_bresp_reg;
    wire m_axil_bvalid_reg;
    wire [DATA_WIDTH-1:0] m_axil_araddr_reg;
    wire [2:0] m_axil_arprot_reg;
    wire m_axil_arvalid_reg;
    wire [DATA_WIDTH-1:0] s_axil_rdata_reg;
    wire [1:0] s_axil_rresp_reg;
    wire s_axil_rvalid_reg;
    wire [DATA_WIDTH-1:0] s_axil_awaddr_reg_d;
    wire [2:0] s_axil_awprot_reg_d;
    wire s_axil_awvalid_reg_d;
    wire [DATA_WIDTH-1:0] s_axil_wdata_reg_d;
    wire [STRB_WIDTH-1:0] s_axil_wstrb_reg_d;
    wire s_axil_wvalid_reg_d;
    wire [DATA_WIDTH-1:0] m_axil_awaddr_reg_d;
    wire [2:0] m_axil_awprot_reg_d;
    wire m_axil_awvalid_reg_d;
    wire [DATA_WIDTH-1:0] m_axil_wdata_reg_d;
    wire [STRB_WIDTH-1:0] m_axil_wstrb_reg_d;
    wire m_axil_wvalid_reg_d;
    wire [1:0] m_axil_bresp_reg_d;
    wire m_axil_bvalid_reg_d;
    wire [DATA_WIDTH-1:0] m_axil_araddr_reg_d;
    wire [2:0] m_axil_arprot_reg_d;
    wire m_axil_arvalid_reg_d;
    wire [DATA_WIDTH-1:0] s_axil_rdata_reg_d;
    wire [1:0] s_axil_rresp_reg_d;
    wire s_axil_rvalid_reg_d;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axil_awaddr_reg <= 0;
            s_axil_awprot_reg <= 0;
            s_axil_awvalid_reg <= 0;
            s_axil_wdata_reg <= 0;
            s_axil_wstrb_reg <= 0;
            s_axil_wvalid_reg <= 0;
        end else begin
            s_axil_awaddr_reg <= s_axil_awaddr;
            s_axil_awprot_reg <= s_axil_awprot;
            s_axil_awvalid_reg <= s_axil_awvalid;
            s_axil_wdata_reg <= s_axil_wdata;
            s_axil_wstrb_reg <= s_axil_wstrb;
            s_axil_wvalid_reg <= s_axil_wvalid;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_awaddr_reg <= 0;
            m_axil_awprot_reg <= 0;
            m_axil_awvalid_reg <= 0;
            m_axil_wdata_reg <= 0;
            m_axil_wstrb_reg <= 0;
            m_axil_wvalid_reg <= 0;
            m_axil_bresp_reg <= 0;
            m_axil_bvalid_reg <= 0;
            m_axil_araddr_reg <= 0;
            m_axil_arprot_reg <= 0;
            m_axil_arvalid_reg <= 0;
            s_axil_rdata_reg <= 0;
            s_axil_rresp_reg <= 0;
            s_axil_rvalid_reg <= 0;
        end else begin
            m_axil_awaddr_reg <= m_axil_awaddr_reg_d;
            m_axil_awprot_reg <= m_axil_awprot_reg_d;
            m_axil_awvalid_reg <= m_axil_awvalid_reg_d;
            m_axil_wdata_reg <= m_axil_wdata_reg_d;
            m_axil_wstrb_reg <= m_axil_wstrb_reg_d;
            m_axil_wvalid_reg <= m_axil_wvalid_reg_d;
            m_axil_bresp_reg <= m_axil_bresp_reg_d;
            m_axil_bvalid_reg <= m_axil_bvalid_reg_d;
            m_axil_araddr_reg <= m_axil_araddr_reg_d;
            m_axil_arprot_reg <= m_axil_arprot_reg_d;
            m_axil_arvalid_reg <= m_axil_arvalid_reg_d;
            s_axil_rdata_reg <= s_axil_rdata_reg_d;
            s_axil_rresp_reg <= s_axil_rresp_reg_d;
            s_axil_rvalid_reg <= s_axil_rvalid_reg_d;
        end
    end

    assign s_axil_awready = m_axil_awready;
    assign s_axil_wready = m_axil_wready;
    assign s_axil_bresp = m_axil_bresp;
    assign s_axil_bvalid = m_axil_bvalid;
    assign s_axil_rdata = s_axil_rdata_reg;
    assign s_axil_rresp = s_axil_rresp_reg;
    assign s_axil_rvalid = s_axil_rvalid_reg;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_awaddr_reg_d <= 0;
            m_axil_awprot_reg_d <= 0;
            m_axil_awvalid_reg_d <= 0;
            m_axil_wdata_reg_d <= 0;
            m_axil_wstrb_reg_d <= 0;
            m_axil_wvalid_reg_d <= 0;
            m_axil_bresp_reg_d <= 0;
            m_axil_bvalid_reg_d <= 0;
            m_axil_araddr_reg_d <= 0;
            m_axil_arprot_reg_d <= 0;
            m_axil_arvalid_reg_d <= 0;
            s_axil_rdata_reg_d <= 0;
            s_axil_rresp_reg_d <= 0;
            s_axil_rvalid_reg_d <= 0;
        end else begin
            m_axil_awaddr_reg_d <= s_axil_awaddr_reg;
            m_axil_awprot_reg_d <= s_axil_awprot_reg;
            m_axil_awvalid_reg_d <= s_axil_awvalid_reg;
            m_axil_wdata_reg_d <= s_axil_wdata_reg;
            m_axil_wstrb_reg_d <= s_axil_wstrb_reg;
            m_axil_wvalid_reg_d <= s_axil_wvalid_reg;
            m_axil_bresp_reg_d <= m_axil_bresp;
            m_axil_bvalid_reg_d <= m_axil_bvalid;
            m_axil_araddr_reg_d <= s_axil_araddr;
            m_axil_arprot_reg_d <= s_axil_arprot;
            m_axil_arvalid_reg_d <= s_axil_arvalid;
            s_axil_rdata_reg_d <= m_axil_rdata;
            s_axil_rresp_reg_d <= m_axil_rresp;
            s_axil_rvalid_reg_d <= m_axil_rvalid;
        end
    end

endmodule
