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

    wire [DATA_WIDTH-1:0] s_axil_rdata_reg;
    wire [1:0] s_axil_rresp_reg;
    wire s_axil_rvalid_reg;
    wire s_axil_bready_reg;

    // Synchronizers for slave to master interface
    wire s_awvalid_sync;
    wire s_awready_sync;
    wire s_wvalid_sync;
    wire s_wready_sync;
    wire s_bready_sync;
    wire s_arvalid_sync;
    wire s_arready_sync;
    wire s_rready_sync;

    // Synchronizers for master to slave interface
    wire m_awaddr_sync;
    wire m_awprot_sync;
    wire m_awvalid_sync;
    wire m_wdata_sync;
    wire m_wstrb_sync;
    wire m_wvalid_sync;
    wire m_bready_sync;
    wire m_araddr_sync;
    wire m_arprot_sync;
    wire m_arvalid_sync;
    wire m_rready_sync;

    // Synchronizer for s_rvalid
    wire s_rvalid_sync;
    wire s_rdata_sync;
    wire s_rresp_sync;

    // Synchronizer for s_bvalid
    wire s_bvalid_sync;
    wire s_bresp_sync;

    // AXI4-Lite slave interface handling
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axil_awready <= 0;
            s_axil_wready <= 0;
            s_axil_bresp <= 2'b00;
            s_axil_bvalid <= 0;
            s_axil_arready <= 0;
            s_axil_rdata <= 0;
            s_axil_rresp <= 2'b00;
            s_axil_rvalid <= 0;
        end else begin
            s_axil_awready <= m_axil_awready;
            s_axil_wready <= m_axil_wready;
            s_axil_bresp <= m_axil_bresp;
            s_axil_bvalid <= m_axil_bvalid;
            s_axil_arready <= m_axil_arready;
            s_axil_rdata <= m_axil_rdata;
            s_axil_rresp <= m_axil_rresp;
            s_axil_rvalid <= m_axil_rvalid;
        end
    end

    // AXI4-Lite master interface handling
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_awaddr <= 0;
            m_axil_awprot <= 0;
            m_axil_awvalid <= 0;
            m_axil_wdata <= 0;
            m_axil_wstrb <= 0;
            m_axil_wvalid <= 0;
            m_axil_bready <= 0;
            m_axil_araddr <= 0;
            m_axil_arprot <= 0;
            m_axil_arvalid <= 0;
            m_axil_rready <= 0;
        end else begin
            m_axil_awaddr <= s_axil_awaddr;
            m_axil_awprot <= s_axil_awprot;
            m_axil_awvalid <= s_axil_awvalid;
            m_axil_wdata <= s_axil_wdata;
            m_axil_wstrb <= s_axil_wstrb;
            m_axil_wvalid <= s_axil_wvalid;
            m_axil_bready <= s_axil_bready;
            m_axil_araddr <= s_axil_araddr;
            m_axil_arprot <= s_axil_arprot;
            m_axil_arvalid <= s_axil_arvalid;
            m_axil_rready <= s_axil_rready;
        end
    end

endmodule
