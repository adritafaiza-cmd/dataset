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
    reg [ADDR_WIDTH-1:0] s_awaddr_reg;
    reg [2:0] s_awprot_reg;
    reg s_awvalid_reg;
    reg s_awready_reg;

    reg [ADDR_WIDTH-1:0] m_awaddr_reg;
    reg [2:0] m_awprot_reg;
    reg m_awvalid_reg;
    reg m_awready_reg;

    // W Channel
    reg [DATA_WIDTH-1:0] s_wdata_reg;
    reg [STRB_WIDTH-1:0] s_wstrb_reg;
    reg s_wvalid_reg;
    reg s_wready_reg;

    reg [DATA_WIDTH-1:0] m_wdata_reg;
    reg [STRB_WIDTH-1:0] m_wstrb_reg;
    reg m_wvalid_reg;
    reg m_wready_reg;

    // B Channel
    reg [1:0] m_bresp_reg;
    reg m_bvalid_reg;
    reg m_bready_reg;

    reg [1:0] s_bresp_reg;
    reg s_bvalid_reg;
    reg s_bready_reg;

    // AR Channel
    reg [ADDR_WIDTH-1:0] s_araddr_reg;
    reg [2:0] s_arprot_reg;
    reg s_arvalid_reg;
    reg s_arready_reg;

    reg [ADDR_WIDTH-1:0] m_araddr_reg;
    reg [2:0] m_arprot_reg;
    reg m_arvalid_reg;
    reg m_arready_reg;

    // R Channel
    reg [DATA_WIDTH-1:0] m_rdata_reg;
    reg [1:0] m_rresp_reg;
    reg m_rvalid_reg;
    reg m_rready_reg;

    reg [DATA_WIDTH-1:0] s_rdata_reg;
    reg [1:0] s_rresp_reg;
    reg s_rvalid_reg;
    reg s_rready_reg;

    // AW Channel Cross Clock Domain
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_awaddr_reg <= 0;
            s_awprot_reg <= 0;
            s_awvalid_reg <= 0;
            s_awready_reg <= 0;
        end else begin
            if (s_axil_awvalid && s_awready_reg) begin
                s_awaddr_reg <= s_axil_awaddr;
                s_awprot_reg <= s_axil_awprot;
                s_awvalid_reg <= 1;
            end else if (m_awready_reg) begin
                s_awvalid_reg <= 0;
            end
            s_awready_reg <= m_awready_reg;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_awaddr_reg <= 0;
            m_awprot_reg <= 0;
            m_awvalid_reg <= 0;
            m_awready_reg <= 0;
        end else begin
            if (s_awvalid_reg && !m_awvalid_reg) begin
                m_awaddr_reg <= s_awaddr_reg;
                m_awprot_reg <= s_awprot_reg;
                m_awvalid_reg <= 1;
            end else if (m_awready_reg) begin
                m_awvalid_reg <= 0;
            end
            m_awready_reg <= s_awready_reg;
        end
    end

    // W Channel Cross Clock Domain
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wdata_reg <= 0;
            s_wstrb_reg <= 0;
            s_wvalid_reg <= 0;
            s_wready_reg <= 0;
        end else begin
            if (s_axil_wvalid && s_wready_reg) begin
                s_wdata_reg <= s_axil_wdata;
                s_wstrb_reg <= s_axil_wstrb;
                s_wvalid_reg <= 1;
            end else if (m_wready_reg) begin
                s_wvalid_reg <= 0;
            end
            s_wready_reg <= m_wready_reg;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_wdata_reg <= 0;
            m_wstrb_reg <= 0;
            m_wvalid_reg <= 0;
            m_wready_reg <= 0;
        end else begin
            if (s_wvalid_reg && !m_wvalid_reg) begin
                m_wdata_reg <= s_wdata_reg;
                m_wstrb_reg <= s_wstrb_reg;
                m_wvalid_reg <= 1;
            end else if (m_wready_reg) begin
                m_wvalid_reg <= 0;
            end
            m_wready_reg <= s_wready_reg;
        end
    end

    // B Channel Cross Clock Domain
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_bresp_reg <= 0;
            m_bvalid_reg <= 0;
            m_bready_reg <= 0;
        end else begin
            if (m_axil_bvalid && !m_bvalid_reg) begin
                m_bresp_reg <= m_axil_bresp;
                m_bvalid_reg <= 1;
            end else if (s_bready_reg) begin
                m_bvalid_reg <= 0;
            end
            m_bready_reg <= s_bready_reg;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_bresp_reg <= 0;
            s_bvalid_reg <= 0;
            s_bready_reg <= 0;
        end else begin
            if (m_bvalid_reg && !s_bvalid_reg) begin
                s_bresp_reg <= m_bresp_reg;
                s_bvalid_reg <= 1;
            end else if (s_bready_reg) begin
                s_bvalid_reg <= 0;
            end
            s_bready_reg <= m_bready_reg;
        end
    end

    // AR Channel Cross Clock Domain
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_araddr_reg <= 0;
            s_arprot_reg <= 0;
            s_arvalid_reg <= 0;
            s_arready_reg <= 0;
        end else begin
            if (s_axil_arvalid && s_arready_reg) begin
                s_araddr_reg <= s_axil_araddr;
                s_arprot_reg <= s_axil_arprot;
                s_arvalid_reg <= 1;
            end else if (m_arready_reg) begin
                s_arvalid_reg <= 0;
            end
            s_arready_reg <= m_arready_reg;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_araddr_reg <= 0;
            m_arprot_reg <= 0;
            m_arvalid_reg <= 0;
            m_arready_reg <= 0;
        end else begin
            if (s_arvalid_reg && !m_arvalid_reg) begin
                m_araddr_reg <= s_araddr_reg;
                m_arprot_reg <= s_arprot_reg;
                m_arvalid_reg <= 1;
            end else if (m_arready_reg) begin
                m_arvalid_reg <= 0;
            end
            m_arready_reg <= s_arready_reg;
        end
    end

    // R Channel Cross Clock Domain
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rdata_reg <= 0;
            m_rresp_reg <= 0;
            m_rvalid_reg <= 0;
            m_rready_reg <= 0;
        end else begin
            if (m_axil_rvalid && !m_rvalid_reg) begin
                m_rdata_reg <= m_axil_rdata;
                m_rresp_reg <= m_axil_rresp;
                m_rvalid_reg <= 1;
            end else if (s_rready_reg) begin
                m_rvalid_reg <= 0;
            end
            m_rready_reg <= s_rready_reg;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_rdata_reg <= 0;
            s_rresp_reg <= 0;
            s_rvalid_reg <= 0;
            s_rready_reg <= 0;
        end else begin
            if (m_rvalid_reg && !s_rvalid_reg) begin
                s_rdata_reg <= m_rdata_reg;
                s_rresp_reg <= m_rresp_reg;
                s_rvalid_reg <= 1;
            end else if (s_rready_reg) begin
                s_rvalid_reg <= 0;
            end
            s_rready_reg <= m_rready_reg;
        end
    end

    // AXI Slave Interface Outputs
    assign s_axil_awready = s_awready_reg;
    assign s_axil_wready = s_wready_reg;
    assign s_axil_bresp = s_bresp_reg;
    assign s_axil_bvalid = s_bvalid_reg;
    assign s_axil_arready = s_arready_reg;
    assign s_axil_rdata = s_rdata_reg;
    assign s_axil_rresp = s_rresp_reg;
    assign s_axil_rvalid = s_rvalid_reg;

    // AXI Master Interface Outputs
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

endmodule
