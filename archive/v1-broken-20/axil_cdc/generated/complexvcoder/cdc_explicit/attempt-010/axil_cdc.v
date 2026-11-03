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

    wire [ADDR_WIDTH-1:0] m_axil_awaddr_reg;
    wire [2:0] m_axil_awprot_reg;
    wire m_axil_awvalid_reg;
    wire m_axil_wvalid_reg;
    wire [DATA_WIDTH-1:0] m_axil_wdata_reg;
    wire [STRB_WIDTH-1:0] m_axil_wstrb_reg;
    wire m_axil_bready_reg;
    wire [ADDR_WIDTH-1:0] m_axil_araddr_reg;
    wire [2:0] m_axil_arprot_reg;
    wire m_axil_arvalid_reg;
    wire m_axil_rready_reg;
    wire s_axil_awready_reg;
    wire s_axil_wready_reg;
    wire [1:0] s_axil_bresp_reg;
    wire s_axil_bvalid_reg;
    wire s_axil_arready_reg;
    wire [DATA_WIDTH-1:0] s_axil_rdata_reg;
    wire [1:0] s_axil_rresp_reg;
    wire s_axil_rvalid_reg;

    // AXI4-Lite to AXI4-Lite bridge logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_axil_awaddr_reg <= 0;
            m_axil_awprot_reg <= 0;
            m_axil_awvalid_reg <= 0;
            m_axil_wvalid_reg <= 0;
            m_axil_wdata_reg <= 0;
            m_axil_wstrb_reg <= 0;
            m_axil_bready_reg <= 0;
            m_axil_araddr_reg <= 0;
            m_axil_arprot_reg <= 0;
            m_axil_arvalid_reg <= 0;
            m_axil_rready_reg <= 0;
            s_axil_awready_reg <= 0;
            s_axil_wready_reg <= 0;
            s_axil_bresp_reg <= 0;
            s_axil_bvalid_reg <= 0;
            s_axil_arready_reg <= 0;
            s_axil_rdata_reg <= 0;
            s_axil_rresp_reg <= 0;
            s_axil_rvalid_reg <= 0;
        end else begin
            if (s_axil_awvalid && m_axil_awready) begin
                m_axil_awaddr_reg <= s_axil_awaddr;
                m_axil_awprot_reg <= s_axil_awprot;
                m_axil_awvalid_reg <= s_axil_awvalid;
                s_axil_awready_reg <= 1;
            end else begin
                s_axil_awready_reg <= 0;
            end

            if (s_axil_wvalid && m_axil_wready) begin
                m_axil_wdata_reg <= s_axil_wdata;
                m_axil_wstrb_reg <= s_axil_wstrb;
                m_axil_wvalid_reg <= s_axil_wvalid;
                s_axil_wready_reg <= 1;
            end else begin
                s_axil_wready_reg <= 0;
            end

            if (s_axil_bready && m_axil_bvalid) begin
                s_axil_bresp_reg <= m_axil_bresp;
                s_axil_bvalid_reg <= 1;
                m_axil_bready_reg <= 1;
            end else begin
                s_axil_bvalid_reg <= 0;
                m_axil_bready_reg <= 0;
            end

            if (s_axil_arvalid && m_axil_arready) begin
                m_axil_araddr_reg <= s_axil_araddr;
                m_axil_arprot_reg <= s_axil_arprot;
                m_axil_arvalid_reg <= s_axil_arvalid;
                s_axil_arready_reg <= 1;
            end else begin
                s_axil_arready_reg <= 0;
            end

            if (s_axil_rready && m_axil_rvalid) begin
                s_axil_rdata_reg <= m_axil_rdata;
                s_axil_rresp_reg <= m_axil_rresp;
                s_axil_rvalid_reg <= 1;
                m_axil_rready_reg <= 1;
            end else begin
                s_axil_rvalid_reg <= 0;
                m_axil_rready_reg <= 0;
            end
        end
    end

    assign m_axil_awaddr = m_axil_awaddr_reg;
    assign m_axil_awprot = m_axil_awprot_reg;
    assign m_axil_awvalid = m_axil_awvalid_reg;
    assign m_axil_wdata = m_axil_wdata_reg;
    assign m_axil_wstrb = m_axil_wstrb_reg;
    assign m_axil_wvalid = m_axil_wvalid_reg;
    assign m_axil_bready = m_axil_bready_reg;
    assign m_axil_araddr = m_axil_araddr_reg;
    assign m_axil_arprot = m_axil_arprot_reg;
    assign m_axil_arvalid = m_axil_arvalid_reg;
    assign m_axil_rready = m_axil_rready_reg;

    assign s_axil_awready = s_axil_awready_reg;
    assign s_axil_wready = s_axil_wready_reg;
    assign s_axil_bresp = s_axil_bresp_reg;
    assign s_axil_bvalid = s_axil_bvalid_reg;
    assign s_axil_arready = s_axil_arready_reg;
    assign s_axil_rdata = s_axil_rdata_reg;
    assign s_axil_rresp = s_axil_rresp_reg;
    assign s_axil_rvalid = s_axil_rvalid_reg;

endmodule
