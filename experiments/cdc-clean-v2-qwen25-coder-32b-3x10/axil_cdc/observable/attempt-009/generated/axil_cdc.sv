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

    // AW Channel
    reg [ADDR_WIDTH-1:0] s_awaddr_r;
    reg [2:0] s_awprot_r;
    reg s_awvalid_r;
    reg s_awready_r;

    reg [ADDR_WIDTH-1:0] m_awaddr_r;
    reg [2:0] m_awprot_r;
    reg m_awvalid_r;
    reg m_awready_r;

    // W Channel
    reg [DATA_WIDTH-1:0] s_wdata_r;
    reg [STRB_WIDTH-1:0] s_wstrb_r;
    reg s_wvalid_r;
    reg s_wready_r;

    reg [DATA_WIDTH-1:0] m_wdata_r;
    reg [STRB_WIDTH-1:0] m_wstrb_r;
    reg m_wvalid_r;
    reg m_wready_r;

    // B Channel
    reg [1:0] m_bresp_r;
    reg m_bvalid_r;
    reg m_bready_r;

    reg [1:0] s_bresp_r;
    reg s_bvalid_r;
    reg s_bready_r;

    // AR Channel
    reg [ADDR_WIDTH-1:0] s_araddr_r;
    reg [2:0] s_arprot_r;
    reg s_arvalid_r;
    reg s_arready_r;

    reg [ADDR_WIDTH-1:0] m_araddr_r;
    reg [2:0] m_arprot_r;
    reg m_arvalid_r;
    reg m_arready_r;

    // R Channel
    reg [DATA_WIDTH-1:0] m_rdata_r;
    reg [1:0] m_rresp_r;
    reg m_rvalid_r;
    reg m_rready_r;

    reg [DATA_WIDTH-1:0] s_rdata_r;
    reg [1:0] s_rresp_r;
    reg s_rvalid_r;
    reg s_rready_r;

    // AW Channel CDC
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_awaddr_r <= 0;
            s_awprot_r <= 0;
            s_awvalid_r <= 0;
            s_awready_r <= 0;
        end else begin
            if (s_axil_awvalid && s_awready_r) begin
                s_awaddr_r <= s_axil_awaddr;
                s_awprot_r <= s_axil_awprot;
                s_awvalid_r <= 1;
            end else if (m_awready_r) begin
                s_awvalid_r <= 0;
            end
            s_awready_r <= m_awready_r;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_awaddr_r <= 0;
            m_awprot_r <= 0;
            m_awvalid_r <= 0;
            m_awready_r <= 0;
        end else begin
            m_awaddr_r <= s_awaddr_r;
            m_awprot_r <= s_awprot_r;
            m_awvalid_r <= s_awvalid_r;
            m_awready_r <= s_awready_r;
        end
    end

    // W Channel CDC
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wdata_r <= 0;
            s_wstrb_r <= 0;
            s_wvalid_r <= 0;
            s_wready_r <= 0;
        end else begin
            if (s_axil_wvalid && s_wready_r) begin
                s_wdata_r <= s_axil_wdata;
                s_wstrb_r <= s_axil_wstrb;
                s_wvalid_r <= 1;
            end else if (m_wready_r) begin
                s_wvalid_r <= 0;
            end
            s_wready_r <= m_wready_r;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_wdata_r <= 0;
            m_wstrb_r <= 0;
            m_wvalid_r <= 0;
            m_wready_r <= 0;
        end else begin
            m_wdata_r <= s_wdata_r;
            m_wstrb_r <= s_wstrb_r;
            m_wvalid_r <= s_wvalid_r;
            m_wready_r <= s_wready_r;
        end
    end

    // B Channel CDC
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_bresp_r <= 0;
            m_bvalid_r <= 0;
            m_bready_r <= 0;
        end else begin
            m_bresp_r <= m_axil_bresp;
            m_bvalid_r <= m_axil_bvalid;
            m_bready_r <= s_bready_r;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_bresp_r <= 0;
            s_bvalid_r <= 0;
            s_bready_r <= 0;
        end else begin
            s_bresp_r <= m_bresp_r;
            s_bvalid_r <= m_bvalid_r;
            s_bready_r <= m_bready_r;
        end
    end

    // AR Channel CDC
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_araddr_r <= 0;
            s_arprot_r <= 0;
            s_arvalid_r <= 0;
            s_arready_r <= 0;
        end else begin
            if (s_axil_arvalid && s_arready_r) begin
                s_araddr_r <= s_axil_araddr;
                s_arprot_r <= s_axil_arprot;
                s_arvalid_r <= 1;
            end else if (m_arready_r) begin
                s_arvalid_r <= 0;
            end
            s_arready_r <= m_arready_r;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_araddr_r <= 0;
            m_arprot_r <= 0;
            m_arvalid_r <= 0;
            m_arready_r <= 0;
        end else begin
            m_araddr_r <= s_araddr_r;
            m_arprot_r <= s_arprot_r;
            m_arvalid_r <= s_arvalid_r;
            m_arready_r <= s_arready_r;
        end
    end

    // R Channel CDC
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rdata_r <= 0;
            m_rresp_r <= 0;
            m_rvalid_r <= 0;
            m_rready_r <= 0;
        end else begin
            m_rdata_r <= m_axil_rdata;
            m_rresp_r <= m_axil_rresp;
            m_rvalid_r <= m_axil_rvalid;
            m_rready_r <= s_rready_r;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_rdata_r <= 0;
            s_rresp_r <= 0;
            s_rvalid_r <= 0;
            s_rready_r <= 0;
        end else begin
            s_rdata_r <= m_rdata_r;
            s_rresp_r <= m_rresp_r;
            s_rvalid_r <= m_rvalid_r;
            s_rready_r <= m_rready_r;
        end
    end

    // Slave Interface Outputs
    assign s_axil_awready = s_awready_r;
    assign s_axil_wready = s_wready_r;
    assign s_axil_bresp = s_bresp_r;
    assign s_axil_bvalid = s_bvalid_r;
    assign s_axil_arready = s_arready_r;
    assign s_axil_rdata = s_rdata_r;
    assign s_axil_rresp = s_rresp_r;
    assign s_axil_rvalid = s_rvalid_r;

    // Master Interface Outputs
    assign m_axil_awaddr = m_awaddr_r;
    assign m_axil_awprot = m_awprot_r;
    assign m_axil_awvalid = m_awvalid_r;
    assign m_axil_wdata = m_wdata_r;
    assign m_axil_wstrb = m_wstrb_r;
    assign m_axil_wvalid = m_wvalid_r;
    assign m_axil_bready = m_bready_r;
    assign m_axil_araddr = m_araddr_r;
    assign m_axil_arprot = m_arprot_r;
    assign m_axil_arvalid = m_arvalid_r;
    assign m_axil_rready = m_rready_r;

endmodule
