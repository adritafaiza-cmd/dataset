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

    // Flip-flops for s_clk domain
    reg [ADDR_WIDTH-1:0] s_axil_awaddr_ff;
    reg [2:0] s_axil_awprot_ff;
    reg s_axil_awvalid_ff;
    reg [DATA_WIDTH-1:0] s_axil_wdata_ff;
    reg [STRB_WIDTH-1:0] s_axil_wstrb_ff;
    reg s_axil_wvalid_ff;
    reg s_axil_bready_ff;
    reg [ADDR_WIDTH-1:0] s_axil_araddr_ff;
    reg [2:0] s_axil_arprot_ff;
    reg s_axil_arvalid_ff;
    reg s_axil_rready_ff;

    // Flip-flops for m_clk domain
    reg [ADDR_WIDTH-1:0] m_axil_awaddr_ff;
    reg [2:0] m_axil_awprot_ff;
    reg m_axil_awvalid_ff;
    reg [DATA_WIDTH-1:0] m_axil_wdata_ff;
    reg [STRB_WIDTH-1:0] m_axil_wstrb_ff;
    reg m_axil_wvalid_ff;
    reg m_axil_bready_ff;
    reg [ADDR_WIDTH-1:0] m_axil_araddr_ff;
    reg [2:0] m_axil_arprot_ff;
    reg m_axil_arvalid_ff;
    reg m_axil_rready_ff;

    // Handshake signals
    reg s_axil_awready_ff;
    reg s_axil_wready_ff;
    reg s_axil_bvalid_ff;
    reg s_axil_arready_ff;
    reg s_axil_rvalid_ff;

    reg m_axil_awready_ff;
    reg m_axil_wready_ff;
    reg m_axil_bvalid_ff;
    reg m_axil_arready_ff;
    reg m_axil_rvalid_ff;

    // Assignments to output ports
    assign s_axil_awready = s_axil_awready_ff;
    assign s_axil_wready = s_axil_wready_ff;
    assign s_axil_bresp = m_axil_bresp;
    assign s_axil_bvalid = m_axil_bvalid;
    assign s_axil_arready = s_axil_arready_ff;
    assign s_axil_rdata = m_axil_rdata;
    assign s_axil_rresp = m_axil_rresp;
    assign s_axil_rvalid = m_axil_rvalid;

    assign m_axil_awaddr = s_axil_awaddr_ff;
    assign m_axil_awprot = s_axil_awprot_ff;
    assign m_axil_awvalid = s_axil_awvalid_ff;
    assign m_axil_wdata = s_axil_wdata_ff;
    assign m_axil_wstrb = s_axil_wstrb_ff;
    assign m_axil_wvalid = s_axil_wvalid_ff;
    assign m_axil_bready = s_axil_bready_ff;
    assign m_axil_araddr = s_axil_araddr_ff;
    assign m_axil_arprot = s_axil_arprot_ff;
    assign m_axil_arvalid = s_axil_arvalid_ff;
    assign m_axil_rready = s_axil_rready_ff;

    // Flip-flop instances
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axil_awaddr_ff <= 0;
            s_axil_awprot_ff <= 0;
            s_axil_awvalid_ff <= 0;
            s_axil_wdata_ff <= 0;
            s_axil_wstrb_ff <= 0;
            s_axil_wvalid_ff <= 0;
            s_axil_bready_ff <= 0;
            s_axil_araddr_ff <= 0;
            s_axil_arprot_ff <= 0;
            s_axil_arvalid_ff <= 0;
            s_axil_rready_ff <= 0;
            s_axil_awready_ff <= 0;
            s_axil_wready_ff <= 0;
            s_axil_bvalid_ff <= 0;
            s_axil_arready_ff <= 0;
            s_axil_rvalid_ff <= 0;
        end else begin
            s_axil_awaddr_ff <= s_axil_awaddr;
            s_axil_awprot_ff <= s_axil_awprot;
            s_axil_awvalid_ff <= s_axil_awvalid;
            s_axil_wdata_ff <= s_axil_wdata;
            s_axil_wstrb_ff <= s_axil_wstrb;
            s_axil_wvalid_ff <= s_axil_wvalid;
            s_axil_bready_ff <= s_axil_bready;
            s_axil_araddr_ff <= s_axil_araddr;
            s_axil_arprot_ff <= s_axil_arprot;
            s_axil_arvalid_ff <= s_axil_arvalid;
            s_axil_rready_ff <= s_axil_rready;
            s_axil_awready_ff <= m_axil_awready;
            s_axil_wready_ff <= m_axil_wready;
            s_axil_bvalid_ff <= m_axil_bvalid;
            s_axil_arready_ff <= m_axil_arready;
            s_axil_rvalid_ff <= m_axil_rvalid;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_awaddr_ff <= 0;
            m_axil_awprot_ff <= 0;
            m_axil_awvalid_ff <= 0;
            m_axil_wdata_ff <= 0;
            m_axil_wstrb_ff <= 0;
            m_axil_wvalid_ff <= 0;
            m_axil_bready_ff <= 0;
            m_axil_araddr_ff <= 0;
            m_axil_arprot_ff <= 0;
            m_axil_arvalid_ff <= 0;
            m_axil_rready_ff <= 0;
            m_axil_awready_ff <= 0;
            m_axil_wready_ff <= 0;
            m_axil_bvalid_ff <= 0;
            m_axil_arready_ff <= 0;
            m_axil_rvalid_ff <= 0;
        end else begin
            m_axil_awaddr_ff <= s_axil_awaddr_ff;
            m_axil_awprot_ff <= s_axil_awprot_ff;
            m_axil_awvalid_ff <= s_axil_awvalid_ff;
            m_axil_wdata_ff <= s_axil_wdata_ff;
            m_axil_wstrb_ff <= s_axil_wstrb_ff;
            m_axil_wvalid_ff <= s_axil_wvalid_ff;
            m_axil_bready_ff <= s_axil_bready_ff;
            m_axil_araddr_ff <= s_axil_araddr_ff;
            m_axil_arprot_ff <= s_axil_arprot_ff;
            m_axil_arvalid_ff <= s_axil_arvalid_ff;
            m_axil_rready_ff <= s_axil_rready_ff;
            m_axil_awready_ff <= 0;
            m_axil_wready_ff <= 0;
            m_axil_bvalid_ff <= 0;
            m_axil_arready_ff <= 0;
            m_axil_rvalid_ff <= 0;
        end
    end

endmodule
