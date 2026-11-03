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

    /*
     * Write Channel
     */
    reg [ADDR_WIDTH-1:0] s_awaddr_reg;
    reg [2:0]            s_awprot_reg;
    reg [DATA_WIDTH-1:0] s_wdata_reg;
    reg [STRB_WIDTH-1:0] s_wstrb_reg;
    reg                  s_awvalid_reg;
    reg                  s_wvalid_reg;
    reg                  s_awvalid_meta;
    reg                  s_wvalid_meta;
    reg                  s_awvalid_sync;
    reg                  s_wvalid_sync;
    reg                  s_awvalid_meta_sync;
    reg                  s_wvalid_meta_sync;
    reg                  m_awvalid_reg;
    reg                  m_wvalid_reg;
    reg                  m_awready_reg;
    reg                  m_wready_reg;
    reg [1:0]            m_bresp_reg;
    reg                  m_bvalid_reg;
    reg                  s_bready_meta;
    reg                  s_bready_sync;
    reg                  s_bready_meta_sync;
    reg                  s_bready_sync_sync;

    /*
     * Read Channel
     */
    reg [ADDR_WIDTH-1:0] s_araddr_reg;
    reg [2:0]            s_arprot_reg;
    reg                  s_arvalid_reg;
    reg                  s_arvalid_meta;
    reg                  s_arvalid_sync;
    reg                  s_arvalid_meta_sync;
    reg                  m_arvalid_reg;
    reg                  m_arready_reg;
    reg [DATA_WIDTH-1:0] m_rdata_reg;
    reg [1:0]            m_rresp_reg;
    reg                  m_rvalid_reg;
    reg                  s_rready_meta;
    reg                  s_rready_sync;
    reg                  s_rready_meta_sync;
    reg                  s_rready_sync_sync;

    /*
     * Write Channel
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_awaddr_reg <= 0;
            s_awprot_reg <= 0;
            s_wdata_reg  <= 0;
            s_wstrb_reg  <= 0;
            s_awvalid_reg <= 0;
            s_wvalid_reg  <= 0;
            s_awvalid_meta <= 0;
            s_wvalid_meta <= 0;
        end else begin
            if (s_axil_awvalid && s_axil_awready) begin
                s_awaddr_reg <= s_axil_awaddr;
                s_awprot_reg <= s_axil_awprot;
                s_awvalid_reg <= 1;
                s_awvalid_meta <= 1;
            end else if (m_axil_awready) begin
                s_awvalid_reg <= 0;
                s_awvalid_meta <= 0;
            end

            if (s_axil_wvalid && s_axil_wready) begin
                s_wdata_reg <= s_axil_wdata;
                s_wstrb_reg <= s_axil_wstrb;
                s_wvalid_reg <= 1;
                s_wvalid_meta <= 1;
            end else if (m_axil_wready) begin
                s_wvalid_reg <= 0;
                s_wvalid_meta <= 0;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_awvalid_sync <= 0;
            s_wvalid_sync <= 0;
            s_awvalid_meta_sync <= 0;
            s_wvalid_meta_sync <= 0;
            m_awvalid_reg <= 0;
            m_wvalid_reg <= 0;
            m_awready_reg <= 0;
            m_wready_reg <= 0;
            m_bresp_reg <= 0;
            m_bvalid_reg <= 0;
            s_bready_meta <= 0;
            s_bready_sync <= 0;
            s_bready_meta_sync <= 0;
            s_bready_sync_sync <= 0;
        end else begin
            s_awvalid_sync <= s_awvalid_meta;
            s_wvalid_sync <= s_wvalid_meta;
            s_awvalid_meta_sync <= s_awvalid_sync;
            s_wvalid_meta_sync <= s_wvalid_sync;

            if (s_awvalid_meta_sync && !m_awvalid_reg) begin
                m_axil_awaddr <= s_awaddr_reg;
                m_axil_awprot <= s_awprot_reg;
                m_awvalid_reg <= 1;
            end else if (m_axil_awready) begin
                m_awvalid_reg <= 0;
            end

            if (s_wvalid_meta_sync && !m_wvalid_reg) begin
                m_axil_wdata <= s_wdata_reg;
                m_axil_wstrb <= s_wstrb_reg;
                m_wvalid_reg <= 1;
            end else if (m_axil_wready) begin
                m_wvalid_reg <= 0;
            end

            m_awready_reg <= m_axil_awready;
            m_wready_reg <= m_axil_wready;

            if (m_axil_bvalid && !s_bready_meta) begin
                m_bresp_reg <= m_axil_bresp;
                m_bvalid_reg <= 1;
                s_bready_meta <= 1;
            end else if (s_axil_bready) begin
                m_bvalid_reg <= 0;
                s_bready_meta <= 0;
            end

            s_bready_sync <= s_bready_meta;
            s_bready_meta_sync <= s_bready_sync;
            s_bready_sync_sync <= s_bready_meta_sync;

            m_axil_bready <= s_bready_sync_sync;
        end
    end

    assign s_axil_awready = !s_awvalid_reg;
    assign s_axil_wready = !s_wvalid_reg;
    assign s_axil_bresp = m_bresp_reg;
    assign s_axil_bvalid = m_bvalid_reg;

    /*
     * Read Channel
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_araddr_reg <= 0;
            s_arprot_reg <= 0;
            s_arvalid_reg <= 0;
            s_arvalid_meta <= 0;
        end else begin
            if (s_axil_arvalid && s_axil_arready) begin
                s_araddr_reg <= s_axil_araddr;
                s_arprot_reg <= s_axil_arprot;
                s_arvalid_reg <= 1;
                s_arvalid_meta <= 1;
            end else if (m_axil_arready) begin
                s_arvalid_reg <= 0;
                s_arvalid_meta <= 0;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_arvalid_sync <= 0;
            s_arvalid_meta_sync <= 0;
            m_arvalid_reg <= 0;
            m_arready_reg <= 0;
            m_rdata_reg <= 0;
            m_rresp_reg <= 0;
            m_rvalid_reg <= 0;
            s_rready_meta <= 0;
            s_rready_sync <= 0;
            s_rready_meta_sync <= 0;
            s_rready_sync_sync <= 0;
        end else begin
            s_arvalid_sync <= s_arvalid_meta;
            s_arvalid_meta_sync <= s_arvalid_sync;

            if (s_arvalid_meta_sync && !m_arvalid_reg) begin
                m_axil_araddr <= s_araddr_reg;
                m_axil_arprot <= s_arprot_reg;
                m_arvalid_reg <= 1;
            end else if (m_axil_arready) begin
                m_arvalid_reg <= 0;
            end

            m_arready_reg <= m_axil_arready;

            if (m_axil_rvalid && !s_rready_meta) begin
                m_rdata_reg <= m_axil_rdata;
                m_rresp_reg <= m_axil_rresp;
                m_rvalid_reg <= 1;
                s_rready_meta <= 1;
            end else if (s_axil_rready) begin
                m_rvalid_reg <= 0;
                s_rready_meta <= 0;
            end

            s_rready_sync <= s_rready_meta;
            s_rready_meta_sync <= s_rready_sync;
            s_rready_sync_sync <= s_rready_meta_sync;

            m_axil_rready <= s_rready_sync_sync;
        end
    end

    assign s_axil_arready = !s_arvalid_reg;
    assign s_axil_rdata = m_rdata_reg;
    assign s_axil_rresp = m_rresp_reg;
    assign s_axil_rvalid = m_rvalid_reg;

endmodule
