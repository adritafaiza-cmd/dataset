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
reg [1:0] s_axil_bresp_reg;
reg s_axil_bvalid_reg;

always @(posedge s_clk or posedge s_rst) begin
    if (s_rst) begin
        s_axil_awaddr_reg <= 0;
        s_axil_awprot_reg <= 0;
        s_axil_awvalid_reg <= 0;
        s_axil_wdata_reg <= 0;
        s_axil_wstrb_reg <= 0;
        s_axil_wvalid_reg <= 0;
        s_axil_bresp_reg <= 0;
        s_axil_bvalid_reg <= 0;
    end else begin
        if (s_axil_awvalid && s_axil_awready) begin
            s_axil_awaddr_reg <= s_axil_awaddr;
            s_axil_awprot_reg <= s_axil_awprot;
            s_axil_awvalid_reg <= 1'b1;
        end else if (m_axil_awready && m_axil_awvalid) begin
            s_axil_awvalid_reg <= 1'b0;
        end

        if (s_axil_wvalid && s_axil_wready) begin
            s_axil_wdata_reg <= s_axil_wdata;
            s_axil_wstrb_reg <= s_axil_wstrb;
            s_axil_wvalid_reg <= 1'b1;
        end else if (m_axil_wready && m_axil_wvalid) begin
            s_axil_wvalid_reg <= 1'b0;
        end

        if (m_axil_bvalid && m_axil_bready) begin
            s_axil_bresp_reg <= m_axil_bresp;
            s_axil_bvalid_reg <= 1'b1;
        end else if (s_axil_bready && s_axil_bvalid) begin
            s_axil_bvalid_reg <= 1'b;
        end
    end
end

assign s_axil_awready = (s_axil_awvalid_reg == 1'b0) && (s_axil_wvalid_reg == 1'b0);
assign s_axil_wready = (s_axil_awvalid_reg == 1'b1) && (s_axil_wvalid_reg == 1'b0);
assign s_axil_bresp = s_axil_bresp_reg;
assign s_axil_bvalid = s_axil_bvalid_reg;

// Read channel
reg [ADDR_WIDTH-1:0] s_axil_araddr_reg;
reg [2:0] s_axil_arprot_reg;
reg s_axil_arvalid_reg;
reg [DATA_WIDTH-1:0] m_axil_rdata_reg;
reg [1:0] m_axil_rresp_reg;
reg m_axil_rvalid_reg;

always @(posedge s_clk or posedge s_rst) begin
    if (s_rst) begin
        s_axil_araddr_reg <= 0;
        s_axil_arprot_reg <= 0;
        s_axil_arvalid_reg <= 0;
        m_axil_rdata_reg <= 0;
        m_axil_rresp_reg <= 0;
        m_axil_rvalid_reg <= 0;
    end else begin
        if (s_axil_arvalid && s_axil_arready) begin
            s_axil_araddr_reg <= s_axil_araddr;
            s_axil_arprot_reg <= s_axil_arprot;
            s_axil_arvalid_reg <= 1'b1;
        end else if (m_axil_arready && m_axil_arvalid) begin
            s_axil_arvalid_reg <= 1'b0;
        end

        if (m_axil_rvalid && m_axil_rready) begin
            m_axil_rdata_reg <= m_axil_rdata;
            m_axil_rresp_reg <= m_axil_rresp;
            m_axil_rvalid_reg <= 1'b1;
        end else if (s_axil_rready && s_axil_rvalid) begin
            m_axil_rvalid_reg <= 1'b0;
        end
    end
end

assign s_axil_arready = (s_axil_arvalid_reg == 1'b0);
assign s_axil_rdata = m_axil_rdata_reg;
assign s_axil_rresp = m_axil_rresp_reg;
assign s_axil_rvalid = m_axil_rvalid_reg;

// Clock domain crossing
reg [ADDR_WIDTH-1:0] m_axil_awaddr_reg;
reg [2:0] m_axil_awprot_reg;
reg m_axil_awvalid_reg;
reg [DATA_WIDTH-1:0] m_axil_wdata_reg;
reg [STRB_WIDTH-1:0] m_axil_wstrb_reg;
reg m_axil_wvalid_reg;
reg [ADDR_WIDTH-1:0] m_axil_araddr_reg;
reg [2:0] m_axil_arprot_reg;
reg m_axil_arvalid_reg;

always @(posedge m_clk or posedge m_rst) begin
    if (m_rst) begin
        m_axil_awaddr_reg <= 0;
        m_axil_awprot_reg <= 0;
        m_axil_awvalid_reg <= 0;
        m_axil_wdata_reg <= 0;
        m_axil_wstrb_reg <= 0;
        m_axil_wvalid_reg <= 0;
        m_axil_araddr_reg <= 0;
        m_axil_arprot_reg <= 0;
        m_axil_arvalid_reg <= 0;
    end else begin
        if (s_axil_awvalid_reg) begin
            m_axil_awaddr_reg <= s_axil_awaddr_reg;
            m_axil_awprot_reg <= s_axil_awprot_reg;
            m_axil_awvalid_reg <= 1'b1;
        end else if (m_axil_awready && m_axil_awvalid) begin
            m_axil_awvalid_reg <= 1'b0;
        end

        if (s_axil_wvalid_reg) begin
            m_axil_wdata_reg <= s_axil_wdata_reg;
            m_axil_wstrb_reg <= s_axil_wstrb_reg;
            m_axil_wvalid_reg <= 1'b1;
        end else if (m_axil_wready && m_axil_wvalid) begin
            m_axil_wvalid_reg <= 1'b0;
        end

        if (s_axil_arvalid_reg) begin
            m_axil_araddr_reg <= s_axil_araddr_reg;
            m_axil_arprot_reg <= s_axil_arprot_reg;
            m_axil_arvalid_reg <= 1'b1;
        end else if (m_axil_arready && m_axil_arvalid) begin
            m_axil_arvalid_reg <= 1'b0;
        end
    end
end

assign m_axil_awaddr = m_axil_awaddr_reg;
assign m_axil_awprot = m_axil_awprot_reg;
assign m_axil_awvalid = m_axil_awvalid_reg;
assign m_axil_wdata = m_axil_wdata_reg;
assign m_axil_wstrb = m_axil_wstrb_reg;
assign m_axil_wvalid = m_axil_wvalid_reg;
assign m_axil_araddr = m_axil_araddr_reg;
assign m_axil_arprot = m_axil_arprot_reg;
assign m_axil_arvalid = m_axil_arvalid_reg;

// Response
reg [1:0] m_axil_bresp_reg;
reg m_axil_bvalid_reg;

always @(posedge m_clk or posedge m_rst) begin
    if (m_rst) begin
        m_axil_bresp_reg <= 0;
        m_axil_bvalid_reg <= 0;
    end else begin
        if (m_axil_bvalid) begin
            m_axil_bresp_reg <= m_axil_bresp;
            m_axil_bvalid_reg <= 1'b1;
        end else if (s_axil_bready && s_axil_bvalid) begin
            m_axil_bvalid_reg <= 1'b0;
        end
    end
end

assign m_axil_bready = (m_axil_bvalid_reg == 1'b0);

// Read response
reg [DATA_WIDTH-1:0] m_axil_rdata_reg2;
reg [1:0] m_axil_rresp_reg2;
reg m_axil_rvalid_reg2;

always @(posedge m_clk or posedge m_rst) begin
    if (m_rst) begin
        m_axil_rdata_reg2 <= 0;
        m_axil_rresp_reg2 <= 0;
        m_axil_rvalid_reg2 <= 0;
    end else begin
        if (m_axil_rvalid) begin
            m_axil_rdata_reg2 <= m_axil_rdata;
            m_axil_rresp_reg2 <= m_axil_rresp;
            m_axil_rvalid_reg2 <= 1'b1;
        end else if (s_axil_rready && s_axil_rvalid) begin
            m_axil_rvalid_reg2 <= 1'b0;
        end
    end
end

assign m_axil_rready = (m_axil_rvalid_reg2 == 1'b0);

endmodule
