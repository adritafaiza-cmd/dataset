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
reg [ADDR_WIDTH-1:0] s_axil_awaddr_reg;
reg [2:0] s_axil_awprot_reg;
reg s_axil_awvalid_reg;
reg [DATA_WIDTH-1:0] s_axil_wdata_reg;
reg [STRB_WIDTH-1:0] s_axil_wstrb_reg;
reg s_axil_wvalid_reg;
reg [1:0] m_axil_bresp_reg;
reg m_axil_bvalid_reg;

always @(posedge s_clk or posedge s_rst) begin
    if (s_rst) begin
        s_axil_awready <= 1'b0;
        s_axil_wready <= 1'b0;
        s_axil_bresp <= 2'b00;
        s_axil_bvalid <= 1'b0;
    end else begin
        if (s_axil_awvalid && s_axil_wvalid && !s_axil_awready && !s_axil_wready) begin
            s_axil_awready <= 1'b1;
            s_axil_wready <= 1'b1;
            s_axil_awaddr_reg <= s_axil_awaddr;
            s_axil_awprot_reg <= s_axil_awprot;
            s_axil_awvalid_reg <= 1'b1;
            s_axil_wdata_reg <= s_axil_wdata;
            s_axil_wstrb_reg <= s_axil_wstrb;
            s_axil_wvalid_reg <= 1'b1;
        end else if (m_axil_bvalid) begin
            s_axil_bresp <= m_axil_bresp_reg;
            s_axil_bvalid <= m_axil_bvalid_reg;
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
        end else begin
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
        end
    end
end

always @(posedge m_clk or posedge m_rst) begin
    if (m_rst) begin
        m_axil_awaddr <= {ADDR_WIDTH{1'b0}};
        m_axil_awprot <= 3'b000;
        m_axil_awvalid <= 1'b0;
        m_axil_wdata <= {DATA_WIDTH{1'b0}};
        m_axil_wstrb <= {STRB_WIDTH{1'b0}};
        m_axil_wvalid <= 1'b0;
        m_axil_bready <= 1'b0;
        m_axil_bresp_reg <= 2'b00;
        m_axil_bvalid_reg <= 1'b0;
    end else begin
        if (s_axil_awvalid_reg && s_axil_wvalid_reg && !m_axil_awvalid) begin
            m_axil_awaddr <= s_axil_awaddr_reg;
            m_axil_awprot <= s_axil_awprot_reg;
            m_axil_awvalid <= 1'b1;
            m_axil_wdata <= s_axil_wdata_reg;
            m_axil_wstrb <= s_axil_wstrb_reg;
            m_axil_wvalid <= 1'b1;
        end else if (m_axil_awready && m_axil_wready) begin
            m_axil_awvalid <= 1'b0;
            m_axil_wvalid <= 1'b0;
        end
        if (m_axil_bvalid) begin
            m_axil_bresp_reg <= m_axil_bresp;
            m_axil_bvalid_reg <= 1'b1;
            m_axil_bready <= 1'b1;
        end else begin
            m_axil_bready <= 1'b0;
        end
    end
end

// Read channel
reg [ADDR_WIDTH-1:0] s_axil_araddr_reg;
reg [2:0] s_axil_arprot_reg;
reg s_axil_arvalid_reg;
reg [DATA_WIDTH-1:0] m_axil_rdata_reg;
reg [1:0] m_axil_rresp_reg;
reg m_axil_rvalid_reg;

always @(posedge s_clk or posedge s_rst) begin
    if (s_rst) begin
        s_axil_arready <= 1'b0;
        s_axil_rdata <= {DATA_WIDTH{1'b0}};
        s_axil_rresp <= 2'b00;
        s_axil_rvalid <= 1'b0;
    end else begin
        if (s_axil_arvalid && !s_axil_arready) begin
            s_axil_arready <= 1'b1;
            s_axil_araddr_reg <= s_axil_araddr;
            s_axil_arprot_reg <= s_axil_arprot;
            s_axil_arvalid_reg <= 1'b1;
        end else if (m_axil_rvalid) begin
            s_axil_rdata <= m_axil_rdata_reg;
            s_axil_rresp <= m_axil_rresp_reg;
            s_axil_rvalid <= m_axil_rvalid_reg;
            s_axil_arready <= 1'b0;
        end else begin
            s_axil_arready <= 1'b0;
        end
    end
end

always @(posedge m_clk or posedge m_rst) begin
    if (m_rst) begin
        m_axil_araddr <= {ADDR_WIDTH{1'b0}};
        m_axil_arprot <= 3'b000;
        m_axil_arvalid <= 1'b0;
        m_axil_rready <= 1'b0;
        m_axil_rdata_reg <= {DATA_WIDTH{1'b0}};
        m_axil_rresp_reg <= 2'b00;
        m_axil_rvalid_reg <= 1'b0;
    end else begin
        if (s_axil_arvalid_reg && !m_axil_arvalid) begin
            m_axil_araddr <= s_axil_araddr_reg;
            m_axil_arprot <= s_axil_arprot_reg;
            m_axil_arvalid <= 1'b1;
        end else if (m_axil_arready) begin
            m_axil_arvalid <= 1'b0;
        end
        if (m_axil_rvalid) begin
            m_axil_rdata_reg <= m_axil_rdata;
            m_axil_rresp_reg <= m_axil_rresp;
            m_axil_rvalid_reg <= 1'b1;
            m_axil_rready <= 1'b1;
        end else begin
            m_axil_rready <= 1'b0;
        end
    end
end

endmodule
