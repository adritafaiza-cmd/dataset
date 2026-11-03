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

// Write channel
reg [ADDR_WIDTH-1:0] s_awaddr;
reg [2:0] s_awprot;
reg s_awvalid;
reg s_awready;
reg [DATA_WIDTH-1:0] s_wdata;
reg [STRB_WIDTH-1:0] s_wstrb;
reg s_wvalid;
reg s_wready;
reg [1:0] s_bresp;
reg s_bvalid;
reg s_bready;

reg [ADDR_WIDTH-1:0] m_awaddr;
reg [2:0] m_awprot;
reg m_awvalid;
reg m_awready;
reg [DATA_WIDTH-1:0] m_wdata;
reg [STRB_WIDTH-1:0] m_wstrb;
reg m_wvalid;
reg m_wready;
reg [1:0] m_bresp;
reg m_bvalid;
reg m_bready;

// Read channel
reg [ADDR_WIDTH-1:0] s_araddr;
reg [2:0] s_arprot;
reg s_arvalid;
reg s_arready;
reg [DATA_WIDTH-1:0] s_rdata;
reg [1:0] s_rresp;
reg s_rvalid;
reg s_rready;

reg [ADDR_WIDTH-1:0] m_araddr;
reg [2:0] m_arprot;
reg m_arvalid;
reg m_arready;
reg [DATA_WIDTH-1:0] m_rdata;
reg [1:0] m_rresp;
reg m_rvalid;
reg m_rready;

// CDC
reg s_awvalid_cdc;
reg s_awready_cdc;
reg s_wvalid_cdc;
reg s_wready_cdc;
reg s_bvalid_cdc;
reg s_bready_cdc;
reg s_arvalid_cdc;
reg s_arready_cdc;
reg s_rvalid_cdc;
reg s_rready_cdc;

reg m_awvalid_cdc;
reg m_awready_cdc;
reg m_wvalid_cdc;
reg m_wready_cdc;
reg m_bvalid_cdc;
reg m_bready_cdc;
reg m_arvalid_cdc;
reg m_arready_cdc;
reg m_rvalid_cdc;
reg m_rready_cdc;

// Slave side
always @(posedge s_clk or posedge s_rst) begin
    if (s_rst) begin
        s_awvalid <= 1'b0;
        s_awready <= 1'b0;
        s_wvalid <= 1'b0;
        s_wready <= 1'b0;
        s_bvalid <= 1'b0;
        s_bready <= 1'b0;
        s_arvalid <= 1'b0;
        s_arready <= 1'b0;
        s_rvalid <= 1'b0;
        s_rready <= 1'b0;
    end else begin
        if (s_axil_awvalid && s_axil_awready) begin
            s_awaddr <= s_axil_awaddr;
            s_awprot <= s_axil_awprot;
            s_awvalid <= 1'b1;
        end else if (s_awvalid && s_awready) begin
            s_awvalid <= 1'b0;
        end

        if (s_axil_wvalid && s_axil_wready) begin
            s_wdata <= s_axil_wdata;
            s_wstrb <= s_axil_wstrb;
            s_wvalid <= 1'b1;
        end else if (s_wvalid && s_wready) begin
            s_wvalid <= 1'b0;
        end

        if (s_axil_bready && s_axil_bvalid) begin
            s_bresp <= s_axil_bresp;
            s_bvalid <= 1'b1;
        end else if (s_bvalid && s_bready) begin
            s_bvalid <= 1'b0;
        end

        if (s_axil_arvalid && s_axil_arready) begin
            s_araddr <= s_axil_araddr;
            s_arprot <= s_axil_arprot;
            s_arvalid <= 1'b1;
        end else if (s_arvalid && s_arready) begin
            s_arvalid <= 1'b0;
        end

        if (s_axil_rready && s_axil_rvalid) begin
            s_rdata <= s_axil_rdata;
            s_rresp <= s_axil_rresp;
            s_rvalid <= 1'b1;
        end else if (s_rvalid && s_rready) begin
            s_rvalid <= 1'b0;
        end
    end
end

always @(posedge s_clk) begin
    s_awready <= s_axil_awvalid &&!s_awvalid;
    s_wready <= s_axil_wvalid &&!s_wvalid;
    s_bready <= s_axil_bvalid &&!s_bvalid;
    s_arready <= s_axil_arvalid &&!s_arvalid;
    s_rready <= s_axil_rvalid &&!s_rvalid;
end

// CDC write channel
always @(posedge m_clk or posedge m_rst) begin
    if (m_rst) begin
        m_awvalid_cdc <= 1'b0;
        m_awready_cdc <= 1'b0;
        m_wvalid_cdc <= 1'b0;
        m_wready_cdc <= 1'b0;
        m_bvalid_cdc <= 1'b0;
        m_bready_cdc <= 1'b0;
    end else begin
        if (s_awvalid_cdc && m_axil_awready) begin
            m_awaddr <= s_awaddr;
            m_awprot <= s_awprot;
            m_awvalid_cdc <= 1'b1;
        end else if (m_awvalid_cdc && m_axil_awready) begin
            m_awvalid_cdc <= 1'b0;
        end

        if (s_wvalid_cdc && m_axil_wready) begin
            m_wdata <= s_wdata;
            m_wstrb <= s_wstrb;
            m_wvalid_cdc <= 1'b1;
        end else if (m_wvalid_cdc && m_axil_wready) begin
            m_wvalid_cdc <= 1'b0;
        end

        if (m_axil_bvalid && m_bready_cdc) begin
            s_bresp <= m_axil_bresp;
            s_bvalid_cdc <= 1'b1;
        end else if (s_bvalid_cdc && s_bready) begin
            s_bvalid_cdc <= 1'b0;
        end
    end
end

always @(posedge m_clk) begin
    m_awready_cdc <= s_awvalid_cdc &&!m_awvalid_cdc;
    m_wready_cdc <= s_wvalid_cdc &&!m_wvalid_cdc;
    m_bready_cdc <= m_axil_bvalid &&!m_bvalid_cdc;
end

// CDC read channel
always @(posedge m_clk or posedge m_rst) begin
    if (m_rst) begin
        m_arvalid_cdc <= 1'b0;
        m_arready_cdc <= 1'b0;
        m_rvalid_cdc <= 1'b0;
        m_rready_cdc <= 1'b0;
    end else begin
        if (s_arvalid_cdc && m_axil_arready) begin
            m_araddr <= s_araddr;
            m_arprot <= s_arprot;
            m_arvalid_cdc <= 1'b1;
        end else if (m_arvalid_cdc && m_axil_arready) begin
            m_arvalid_cdc <= 1'b0;
        end

        if (m_axil_rvalid && m_rready_cdc) begin
            s_rdata <= m_axil_rdata;
            s_rresp <= m_axil_rresp;
            s_rvalid_cdc <= 1'b1;
        end else if (s_rvalid_cdc && s_rready) begin
            s_rvalid_cdc <= 1'b0;
        end
    end
end

always @(posedge m_clk) begin
    m_arready_cdc <= s_arvalid_cdc &&!m_arvalid_cdc;
    m_rready_cdc <= m_axil_rvalid &&!m_rvalid_cdc;
end

// CDC handshake
always @(posedge s_clk) begin
    s_awvalid_cdc <= s_awvalid;
    s_wvalid_cdc <= s_wvalid;
    s_bvalid_cdc <= s_bvalid;
    s_arvalid_cdc <= s_arvalid;
    s_rvalid_cdc <= s_rvalid;
end

always @(posedge m_clk) begin
    m_axil_awaddr <= m_awaddr;
    m_axil_awprot <= m_awprot;
    m_axil_awvalid <= m_awvalid_cdc;
    m_axil_wdata <= m_wdata;
    m_axil_wstrb <= m_wstrb;
    m_axil_wvalid <= m_wvalid_cdc;
    m_axil_bready <= m_bready_cdc;
    m_axil_araddr <= m_araddr;
    m_axil_arprot <= m_arprot;
    m_axil_arvalid <= m_arvalid_cdc;
    m_axil_rready <= m_rready_cdc;
end

assign s_axil_awready = s_awready;
assign s_axil_wready = s_wready;
assign s_axil_bresp = s_bresp;
assign s_axil_bvalid = s_bvalid_cdc;
assign s_axil_arready = s_arready;
assign s_axil_rdata = s_rdata;
assign s_axil_rresp = s_rresp;
assign s_axil_rvalid = s_rvalid_cdc;

endmodule
