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

    // Internal signals
    reg [ADDR_WIDTH-1:0] s_awaddr_reg;
    reg [2:0] s_awprot_reg;
    reg s_awvalid_reg;
    reg [DATA_WIDTH-1:0] s_wdata_reg;
    reg [STRB_WIDTH-1:0] s_wstrb_reg;
    reg s_wvalid_reg;
    reg s_bready_reg;
    reg [ADDR_WIDTH-1:0] s_araddr_reg;
    reg [2:0] s_arprot_reg;
    reg s_arvalid_reg;
    reg s_rready_reg;

    reg [ADDR_WIDTH-1:0] m_awaddr_reg;
    reg [2:0] m_awprot_reg;
    reg m_awvalid_reg;
    reg [DATA_WIDTH-1:0] m_wdata_reg;
    reg [STRB_WIDTH-1:0] m_wstrb_reg;
    reg m_wvalid_reg;
    reg m_bready_reg;
    reg [ADDR_WIDTH-1:0] m_araddr_reg;
    reg [2:0] m_arprot_reg;
    reg m_arvalid_reg;
    reg m_rready_reg;

    wire s_awready;
    wire s_wready;
    wire s_bvalid;
    wire s_rvalid;

    wire m_awvalid;
    wire m_wvalid;
    wire m_bvalid;
    wire m_rvalid;

    // AXI4-Lite Slave to Master handshake logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_awready <= 1'b0;
            s_wready <= 1'b0;
            s_bvalid <= 1'b0;
            s_rvalid <= 1'b0;
        end else begin
            s_awready <= (m_awready & m_axil_awvalid) | (s_axil_awready & s_axil_awvalid);
            s_wready <= (m_wready & m_axil_wvalid) | (s_axil_wready & s_axil_wvalid);
            s_bvalid <= m_bvalid & m_axil_bready;
            s_rvalid <= m_rvalid & m_axil_rready;
        end
    end

    // AXI4-Lite Master to Slave handshake logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_awaddr_reg <= 32'b0;
            m_awprot_reg <= 3'b0;
            m_awvalid_reg <= 1'b0;
            m_wdata_reg <= DATA_WIDTH'b0;
            m_wstrb_reg <= STRB_WIDTH'b0;
            m_wvalid_reg <= 1'b0;
            m_bready_reg <= 1'b0;
            m_araddr_reg <= 32'b0;
            m_arprot_reg <= 3'b0;
            m_arvalid_reg <= 1'b0;
            m_rready_reg <= 1'b0;
        end else begin
            m_awaddr_reg <= s_axil_awaddr;
            m_awprot_reg <= s_axil_awprot;
            m_awvalid_reg <= s_axil_awvalid & s_axil_awready;
            m_wdata_reg <= s_axil_wdata;
            m_wstrb_reg <= s_axil_wstrb;
            m_wvalid_reg <= s_axil_wvalid & s_axil_wready;
            m_bready_reg <= s_axil_bready;
            m_araddr_reg <= s_axil_araddr;
            m_arprot_reg <= s_axil_arprot;
            m_arvalid_reg <= s_axil_arvalid & s_axil_arready;
            m_rready_reg <= s_axil_rready;
        end
    end

    // AXI4-Lite Master interface
    assign m_axil_awaddr = m_awaddr_reg;
    assign m_axil_awprot = m_awprot_reg;
    assign m_axil_awvalid = m_awvalid_reg;
    assign m_axil_wdata = m_wdata_reg;
    assign m_axil_wstrb = m_wstrb_reg;
    assign m_axil_wvalid = m_wvalid_reg;
    assign m_axil_bready = m_bready_reg;
    assign m_axil_araddr = m_araddr_reg;
    assign m_axil_arprot = m_arprot_reg;
    assign m_axil_arvalid = m_arvalid_reg;
    assign m_axil_rready = m_rready_reg;

    // AXI4-Lite Slave interface
    assign s_axil_awready = s_awready;
    assign s_axil_wready = s_wready;
    assign s_axil_bresp = m_axil_bresp;
    assign s_axil_bvalid = s_bvalid;
    assign s_axil_arready = s_arready;
    assign s_axil_rdata = m_axil_rdata;
    assign s_axil_rresp = m_axil_rresp;
    assign s_axil_rvalid = s_rvalid;

endmodule
