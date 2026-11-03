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

    // Internal signals for AXI-Lite slave interface
    reg [ADDR_WIDTH-1:0] s_awaddr_reg;
    reg [2:0] s_awprot_reg;
    reg s_awvalid_reg;
    wire s_awready;
    reg [DATA_WIDTH-1:0] s_wdata_reg;
    reg [STRB_WIDTH-1:0] s_wstrb_reg;
    reg s_wvalid_reg;
    wire s_wready;
    wire [1:0] s_bresp;
    wire s_bvalid;
    reg s_bready_reg;
    reg [ADDR_WIDTH-1:0] s_araddr_reg;
    reg [2:0] s_arprot_reg;
    reg s_arvalid_reg;
    wire s_arready;
    wire [DATA_WIDTH-1:0] s_rdata;
    wire [1:0] s_rresp;
    wire s_rvalid;
    reg s_rready_reg;

    // Internal signals for AXI-Lite master interface
    reg [ADDR_WIDTH-1:0] m_awaddr_reg;
    reg [2:0] m_awprot_reg;
    reg m_awvalid_reg;
    wire m_awready;
    reg [DATA_WIDTH-1:0] m_wdata_reg;
    reg [STRB_WIDTH-1:0] m_wstrb_reg;
    reg m_wvalid_reg;
    wire m_wready;
    wire [1:0] m_bresp;
    wire m_bvalid;
    reg m_bready_reg;
    reg [ADDR_WIDTH-1:0] m_araddr_reg;
    reg [2:0] m_arprot_reg;
    reg m_arvalid_reg;
    wire m_arready;
    wire [DATA_WIDTH-1:0] m_rdata;
    wire [1:0] m_rresp;
    wire m_rvalid;

    // Clock-domain crossing for AXI-Lite slave interface
    axil_cdc_write_bridge #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .STRB_WIDTH(STRB_WIDTH)
    ) write_bridge (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_axil_awaddr(s_awaddr_reg),
        .s_axil_awprot(s_awprot_reg),
        .s_axil_awvalid(s_awvalid_reg),
        .s_axil_awready(s_awready),
        .s_axil_wdata(s_wdata_reg),
        .s_axil_wstrb(s_wstrb_reg),
        .s_axil_wvalid(s_wvalid_reg),
        .s_axil_wready(s_wready),
        .s_axil_bresp(s_bresp),
        .s_axil_bvalid(s_bvalid),
        .s_axil_bready(s_bready_reg),
        .m_axil_awaddr(m_axil_awaddr),
        .m_axil_awprot(m_axil_awprot),
        .m_axil_awvalid(m_awvalid_reg),
        .m_axil_awready(m_awready),
        .m_axil_wdata(m_wdata_reg),
        .m_axil_wstrb(m_wstrb_reg),
        .m_axil_wvalid(m_wvalid_reg),
        .m_axil_wready(m_wready),
        .m_axil_bresp(m_bresp),
        .m_axil_bvalid(m_bvalid),
        .m_axil_bready(m_bready_reg)
    );

    axil_cdc_read_bridge #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .STRB_WIDTH(STRB_WIDTH)
    ) read_bridge (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_axil_araddr(s_araddr_reg),
        .s_axil_arprot(s_arprot_reg),
        .s_axil_arvalid(s_arvalid_reg),
        .s_axil_arready(s_arready),
        .s_axil_rdata(s_rdata),
        .s_axil_rresp(s_rresp),
        .s_axil_rvalid(s_rvalid),
        .s_axil_rready(s_rready_reg),
        .m_axil_araddr(m_araddr_reg),
        .m_axil_arprot(m_arprot_reg),
        .m_axil_arvalid(m_arvalid_reg),
        .m_axil_arready(m_arready),
        .m_axil_rdata(m_rdata),
        .m_axil_rresp(m_rresp),
        .m_axil_rvalid(m_rvalid),
        .m_axil_rready(m_rready_reg)
    );

    // Handle AXI-Lite slave interface
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_awaddr_reg <= 0;
            s_awprot_reg <= 0;
            s_awvalid_reg <= 0;
            s_wdata_reg <= 0;
            s_wstrb_reg <= 0;
            s_wvalid_reg <= 0;
            s_bready_reg <= 0;
            s_araddr_reg <= 0;
            s_arprot_reg <= 0;
            s_arvalid_reg <= 0;
            s_rready_reg <= 0;
        end else begin
            s_awaddr_reg <= s_axil_awaddr;
            s_awprot_reg <= s_axil_awprot;
            s_awvalid_reg <= s_axil_awvalid;
            s_wdata_reg <= s_axil_wdata;
            s_wstrb_reg <= s_axil_wstrb;
            s_wvalid_reg <= s_axil_wvalid;
            s_bready_reg <= s_axil_bready;
            s_araddr_reg <= s_axil_araddr;
            s_arprot_reg <= s_axil_arprot;
            s_arvalid_reg <= s_axil_arvalid;
            s_rready_reg <= s_axil_rready;
        end
    end

    // Handle AXI-Lite master interface
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_awaddr_reg <= 0;
            m_awprot_reg <= 0;
            m_awvalid_reg <= 0;
            m_wdata_reg <= 0;
            m_wstrb_reg <= 0;
            m_wvalid_reg <= 0;
            m_bready_reg <= 0;
            m_araddr_reg <= 0;
            m_arprot_reg <= 0;
            m_arvalid_reg <= 0;
            m_rready_reg <= 0;
        end else begin
            m_awaddr_reg <= m_axil_awaddr;
            m_awprot_reg <= m_axil_awprot;
            m_awvalid_reg <= m_axil_awvalid;
            m_wdata_reg <= m_axil_wdata;
            m_wstrb_reg <= m_axil_wstrb;
            m_wvalid_reg <= m_axil_wvalid;
            m_bready_reg <= m_axil_bready;
            m_araddr_reg <= m_axil_araddr;
            m_arprot_reg <= m_axil_arprot;
            m_arvalid_reg <= m_axil_arvalid;
            m_rready_reg <= m_axil_rready;
        end
    end

endmodule

module axil_cdc_write_bridge #
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
    output wire                   m_axil_bready
);

    // Internal signals
    reg [ADDR_WIDTH-1:0] awaddr_reg;
    reg [2:0] awprot_reg;
    reg awvalid_reg;
    reg [DATA_WIDTH-1:0] wdata_reg;
    reg [STRB_WIDTH-1:0] wstrb_reg;
    reg wvalid_reg;
    reg bready_reg;

    // Handle AXI-Lite write transactions
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            awaddr_reg <= 0;
            awprot_reg <= 0;
            awvalid_reg <= 0;
            wdata_reg <= 0;
            wstrb_reg <= 0;
            wvalid_reg <= 0;
            bready_reg <= 0;
        end else begin
            if (s_axil_awvalid && s_axil_awready) begin
                awaddr_reg <= s_axil_awaddr;
                awprot_reg <= s_axil_awprot;
                awvalid_reg <= 0;
            end else if (s_axil_awvalid) begin
                awaddr_reg <= s_axil_awaddr;
                awprot_reg <= s_axil_awprot;
                awvalid_reg <= 1;
            end

            if (s_axil_wvalid && s_axil_wready) begin
                wdata_reg <= s_axil_wdata;
                wstrb_reg <= s_axil_wstrb;
                wvalid_reg <= 0;
            end else if (s_axil_wvalid) begin
                wdata_reg <= s_axil_wdata;
                wstrb_reg <= s_axil_wstrb;
                wvalid_reg <= 1;
            end

            if (s_axil_bready && m_axil_bvalid) begin
                s_axil_bresp <= m_axil_bresp;
                s_axil_bvalid <= 0;
            end else if (m_axil_bvalid) begin
                s_axil_bresp <= m_axil_bresp;
                s_axil_bvalid <= 1;
            end

            if (m_axil_awready) begin
                m_axil_awaddr <= awaddr_reg;
                m_axil_awprot <= awprot_reg;
                m_axil_awvalid <= awvalid_reg;
            end

            if (m_axil_wready) begin
                m_axil_wdata <= wdata_reg;
                m_axil_wstrb <= wstrb_reg;
                m_axil_wvalid <= wvalid_reg;
            end

            if (m_axil_bready) begin
                m_axil_bready <= 1;
            end else begin
                m_axil_bready <= 0;
            end
        end
    end

    assign s_axil_awready = m_axil_awready;
    assign s_axil_wready = m_axil_wready;

endmodule

module axil_cdc_read_bridge #
(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = (DATA_WIDTH/8)
)
(
    input  wire                   s_clk,
    input  wire                   s_rst,
    input  wire [ADDR_WIDTH-1:0]  s_axil_araddr,
    input  wire [2:0]             s_axil_arprot,
    input  wire                   s_axil_arvalid,
    output wire                   s_axil_arready,
    output wire [DATA_WIDTH-1:0]  s_axil_rdata,
    output wire [1:0]             s_axil_rresp,
    output wire                   s_axil_rvalid,
    input  wire                   s_axil_rready,
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
    reg [ADDR_WIDTH-1:0] araddr_reg;
    reg [2:0] arprot_reg;
    reg arvalid_reg;
    reg rready_reg;

    // Handle AXI-Lite read transactions
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            araddr_reg <= 0;
            arprot_reg <= 0;
            arvalid_reg <= 0;
            rready_reg <= 0;
        end else begin
            if (s_axil_arvalid && s_axil_arready) begin
                araddr_reg <= s_axil_araddr;
                arprot_reg <= s_axil_arprot;
                arvalid_reg <= 0;
            end else if (s_axil_arvalid) begin
                araddr_reg <= s_axil_araddr;
                arprot_reg <= s_axil_arprot;
                arvalid_reg <= 1;
            end

            if (m_axil_rvalid && s_axil_rready) begin
                s_axil_rdata <= m_axil_rdata;
                s_axil_rresp <= m_axil_rresp;
                s_axil_rvalid <= 0;
            end else if (s_axil_rready) begin
                s_axil_rdata <= m_axil_rdata;
                s_axil_rresp <= m_axil_rresp;
                s_axil_rvalid <= 1;
            end

            if (m_axil_arready) begin
                m_axil_araddr <= araddr_reg;
                m_axil_arprot <= arprot_reg;
                m_axil_arvalid <= arvalid_reg;
            end

            if (m_axil_rvalid) begin
                m_axil_rready <= 1;
            end else begin
                m_axil_rready <= 0;
            end
        end
    end

    assign s_axil_arready = m_axil_arready;

endmodule
