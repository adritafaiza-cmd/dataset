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

reg [ADDR_WIDTH-1:0] s_awaddr;
reg [2:0] s_awprot;
reg s_awvalid;
reg [DATA_WIDTH-1:0] s_wdata;
reg [STRB_WIDTH-1:0] s_wstrb;
reg s_wvalid;
reg [1:0] s_bresp;
reg s_bvalid;
reg [ADDR_WIDTH-1:0] s_araddr;
reg [2:0] s_arprot;
reg s_arvalid;
reg [DATA_WIDTH-1:0] s_rdata;
reg [1:0] s_rresp;
reg s_rvalid;

reg [ADDR_WIDTH-1:0] m_awaddr;
reg [2:0] m_awprot;
reg m_awvalid;
reg [DATA_WIDTH-1:0] m_wdata;
reg [STRB_WIDTH-1:0] m_wstrb;
reg m_wvalid;
reg [1:0] m_bresp;
reg m_bvalid;
reg [ADDR_WIDTH-1:0] m_araddr;
reg [2:0] m_arprot;
reg m_arvalid;
reg [DATA_WIDTH-1:0] m_rdata;
reg [1:0] m_rresp;
reg m_rvalid;

reg s_awready;
reg s_wready;
reg s_arready;
reg s_bready;
reg s_rready;
reg m_awready;
reg m_wready;
reg m_arready;
reg m_bready;
reg m_rready;

always @(posedge s_clk or posedge s_rst) begin
    if (s_rst) begin
        s_awvalid <= 1'b0;
        s_wvalid <= 1'b0;
        s_arvalid <= 1'b0;
        s_bvalid <= 1'b0;
        s_rvalid <= 1'b0;
        s_awready <= 1'b0;
        s_wready <= 1'b0;
        s_arready <= 1'b0;
        s_bready <= 1'b0;
        s_rready <= 1'b0;
    end else begin
        if (s_axil_awvalid && s_axil_awready) begin
            s_awaddr <= s_axil_awaddr;
            s_awprot <= s_axil_awprot;
            s_awvalid <= 1'b1;
        end else if (m_axil_awready) begin
            s_awvalid <= 1'b0;
        end

        if (s_axil_wvalid && s_axil_wready) begin
            s_wdata <= s_axil_wdata;
            s_wstrb <= s_axil_wstrb;
            s_wvalid <= 1'b1;
        end else if (m_axil_wready) begin
            s_wvalid <= 1'b0;
        end

        if (s_axil_arvalid && s_axil_arready) begin
            s_araddr <= s_axil_araddr;
            s_arprot <= s_axil_arprot;
            s_arvalid <= 1'b1;
        end else if (m_axil_arready) begin
            s_arvalid <= 1'b0;
        end

        if (m_axil_bvalid && m_axil_bready) begin
            s_bresp <= m_axil_bresp;
            s_bvalid <= 1'b1;
        end else if (s_axil_bready) begin
            s_bvalid <= 1'b0;
        end

        if (m_axil_rvalid && m_axil_rready) begin
            s_rdata <= m_axil_rdata;
            s_rresp <= m_axil_rresp;
            s_rvalid <= 1'b1;
        end else if (s_axil_rready) begin
            s_rvalid <= 1'b0;
        end

        s_awready <= (s_axil_awvalid && !s_awvalid) || (m_axil_awready && s_awvalid);
        s_wready <= (s_axil_wvalid && !s_wvalid) || (m_axil_wready && s_wvalid);
        s_arready <= (s_axil_arvalid && !s_arvalid) || (m_axil_arready && s_arvalid);
        s_bready <= (m_axil_bvalid && !s_bvalid) || (s_axil_bready && s_bvalid);
        s_rready <= (m_axil_rvalid && !s_rvalid) || (s_axil_rready && s_rvalid);
    end
end

always @(posedge m_clk or posedge m_rst) begin
    if (m_rst) begin
        m_awvalid <= 1'b0;
        m_wvalid <= 1'b0;
        m_arvalid <= 1'b0;
        m_bvalid <= 1'b0;
        m_rvalid <= 1'b0;
        m_awready <= 1'b0;
        m_wready <= 1'b0;
        m_arready <= 1'b0;
        m_bready <= 1'b0;
        m_rready <= 1'b0;
    end else begin
        if (s_awvalid && m_axil_awready) begin
            m_awaddr <= s_awaddr;
            m_awprot <= s_awprot;
            m_awvalid <= 1'b1;
        end else if (m_axil_awready) begin
            m_awvalid <= 1'b0;
        end

        if (s_wvalid && m_axil_wready) begin
            m_wdata <= s_wdata;
            m_wstrb <= s_wstrb;
            m_wvalid <= 1'b1;
        end else if (m_axil_wready) begin
            m_wvalid <= 1'b0;
        end

        if (s_arvalid && m_axil_arready) begin
            m_araddr <= s_araddr;
            m_arprot <= s_arprot;
            m_arvalid <= 1'b1;
        end else if (m_axil_arready) begin
            m_arvalid <= 1'b0;
        end

        if (m_axil_bvalid && m_axil_bready) begin
            m_bresp <= m_axil_bresp;
            m_bvalid <= 1'b1;
        end else if (m_axil_bready) begin
            m_bvalid <= 1'b0;
        end

        if (m_axil_rvalid && m_axil_rready) begin
            m_rdata <= m_axil_rdata;
            m_rresp <= m_axil_rresp;
            m_rvalid <= 1'b1;
        end else if (m_axil_rready) begin
            m_rvalid <= 1'b0;
        end

        m_awready <= (s_awvalid && !m_awvalid) || (m_axil_awready && m_awvalid);
        m_wready <= (s_wvalid && !m_wvalid) || (m_axil_wready && m_wvalid);
        m_arready <= (s_arvalid && !m_arvalid) || (m_axil_arready && m_arvalid);
        m_bready <= (m_axil_bvalid && !m_bvalid) || (m_axil_bready && m_bvalid);
        m_rready <= (m_axil_rvalid && !m_rvalid) || (m_axil_rready && m_rvalid);
    end
end

assign s_axil_awready = s_awready;
assign s_axil_wready = s_wready;
assign s_axil_arready = s_arready;
assign s_axil_bresp = s_bresp;
assign s_axil_bvalid = s_bvalid;
assign s_axil_rdata = s_rdata;
assign s_axil_rresp = s_rresp;
assign s_axil_rvalid = s_rvalid;

assign m_axil_awaddr = m_awaddr;
assign m_axil_awprot = m_awprot;
assign m_axil_awvalid = m_awvalid;
assign m_axil_wdata = m_wdata;
assign m_axil_wstrb = m_wstrb;
assign m_axil_wvalid = m_wvalid;
assign m_axil_bready = m_bready;
assign m_axil_araddr = m_araddr;
assign m_axil_arprot = m_arprot;
assign m_axil_arvalid = m_arvalid;
assign m_axil_rready = m_rready;

endmodule
