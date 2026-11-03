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
     * Write channel signals
     */
    reg [ADDR_WIDTH-1:0]          s_awaddr_reg;
    reg [2:0]                     s_awprot_reg;
    reg                           s_awvalid_reg;
    reg [DATA_WIDTH-1:0]          s_wdata_reg;
    reg [STRB_WIDTH-1:0]          s_wstrb_reg;
    reg                           s_wvalid_reg;
    reg [1:0]                     m_bresp_reg;
    reg                           m_bvalid_reg;
    reg                           s_bready_reg;

    /*
     * Read channel signals
     */
    reg [ADDR_WIDTH-1:0]          s_araddr_reg;
    reg [2:0]                     s_arprot_reg;
    reg                           s_arvalid_reg;
    reg [DATA_WIDTH-1:0]          m_rdata_reg;
    reg [1:0]                     m_rresp_reg;
    reg                           m_rvalid_reg;
    reg                           s_rready_reg;

    /*
     * Write channel synchronization
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_awaddr_reg  <= 0;
            s_awprot_reg  <= 0;
            s_awvalid_reg <= 0;
            s_wdata_reg   <= 0;
            s_wstrb_reg   <= 0;
            s_wvalid_reg  <= 0;
            s_bready_reg  <= 0;
        end else begin
            if (s_axil_awvalid && s_axil_awready) begin
                s_awaddr_reg  <= s_axil_awaddr;
                s_awprot_reg  <= s_axil_awprot;
                s_awvalid_reg <= 1;
            end else if (m_axil_awready) begin
                s_awvalid_reg <= 0;
            end

            if (s_axil_wvalid && s_axil_wready) begin
                s_wdata_reg   <= s_axil_wdata;
                s_wstrb_reg   <= s_axil_wstrb;
                s_wvalid_reg  <= 1;
            end else if (m_axil_wready) begin
                s_wvalid_reg  <= 0;
            end

            if (m_axil_bvalid && s_axil_bready) begin
                s_bready_reg  <= 0;
            end else if (s_axil_bready && !m_axil_bvalid) begin
                s_bready_reg  <= 1;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_awaddr  <= 0;
            m_axil_awprot  <= 0;
            m_axil_awvalid <= 0;
            m_axil_wdata   <= 0;
            m_axil_wstrb   <= 0;
            m_axil_wvalid  <= 0;
            m_bresp_reg    <= 0;
            m_bvalid_reg   <= 0;
        end else begin
            if (s_awvalid_reg && !m_axil_awvalid) begin
                m_axil_awaddr  <= s_awaddr_reg;
                m_axil_awprot  <= s_awprot_reg;
                m_axil_awvalid <= 1;
            end else if (m_axil_awready) begin
                m_axil_awvalid <= 0;
            end

            if (s_wvalid_reg && !m_axil_wvalid) begin
                m_axil_wdata   <= s_wdata_reg;
                m_axil_wstrb   <= s_wstrb_reg;
                m_axil_wvalid  <= 1;
            end else if (m_axil_wready) begin
                m_axil_wvalid  <= 0;
            end

            if (m_axil_bvalid && !m_bvalid_reg) begin
                m_bresp_reg    <= m_axil_bresp;
                m_bvalid_reg   <= 1;
            end else if (s_bready_reg) begin
                m_bvalid_reg   <= 0;
            end
        end
    end

    assign s_axil_awready = !s_awvalid_reg;
    assign s_axil_wready  = !s_wvalid_reg;
    assign s_axil_bresp   = m_bresp_reg;
    assign s_axil_bvalid  = m_bvalid_reg;

    /*
     * Read channel synchronization
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_araddr_reg  <= 0;
            s_arprot_reg  <= 0;
            s_arvalid_reg <= 0;
            s_rready_reg  <= 0;
        end else begin
            if (s_axil_arvalid && s_axil_arready) begin
                s_araddr_reg  <= s_axil_araddr;
                s_arprot_reg  <= s_axil_arprot;
                s_arvalid_reg <= 1;
            end else if (m_axil_arready) begin
                s_arvalid_reg <= 0;
            end

            if (m_axil_rvalid && s_axil_rready) begin
                s_rready_reg  <= 0;
            end else if (s_axil_rready && !m_axil_rvalid) begin
                s_rready_reg  <= 1;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_araddr  <= 0;
            m_axil_arprot  <= 0;
            m_axil_arvalid <= 0;
            m_rdata_reg    <= 0;
            m_rresp_reg    <= 0;
            m_rvalid_reg   <= 0;
        end else begin
            if (s_arvalid_reg && !m_axil_arvalid) begin
                m_axil_araddr  <= s_araddr_reg;
                m_axil_arprot  <= s_arprot_reg;
                m_axil_arvalid <= 1;
            end else if (m_axil_arready) begin
                m_axil_arvalid <= 0;
            end

            if (m_axil_rvalid && !m_rvalid_reg) begin
                m_rdata_reg    <= m_axil_rdata;
                m_rresp_reg    <= m_axil_rresp;
                m_rvalid_reg   <= 1;
            end else if (s_rready_reg) begin
                m_rvalid_reg   <= 0;
            end
        end
    end

    assign s_axil_arready = !s_arvalid_reg;
    assign s_axil_rdata   = m_rdata_reg;
    assign s_axil_rresp   = m_rresp_reg;
    assign s_axil_rvalid  = m_rvalid_reg;

    assign m_axil_bready  = s_bready_reg;
    assign m_axil_rready  = s_rready_reg;

endmodule
