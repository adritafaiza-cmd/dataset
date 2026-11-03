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

    // Slave to Master signals
    reg [ADDR_WIDTH-1:0] s2m_awaddr_reg;
    reg [2:0] s2m_awprot_reg;
    reg s2m_awvalid_reg;
    reg [DATA_WIDTH-1:0] s2m_wdata_reg;
    reg [STRB_WIDTH-1:0] s2m_wstrb_reg;
    reg s2m_wvalid_reg;
    reg [ADDR_WIDTH-1:0] s2m_araddr_reg;
    reg [2:0] s2m_arprot_reg;
    reg s2m_arvalid_reg;

    // Master to Slave signals
    reg [1:0] m2s_bresp_reg;
    reg m2s_bvalid_reg;
    reg [DATA_WIDTH-1:0] m2s_rdata_reg;
    reg [1:0] m2s_rresp_reg;
    reg m2s_rvalid_reg;

    // Synchronizers
    reg [1:0] s_awvalid_sync;
    reg [1:0] s_wvalid_sync;
    reg [1:0] s_arvalid_sync;
    reg [1:0] m_awready_sync;
    reg [1:0] m_wready_sync;
    reg [1:0] m_arready_sync;
    reg [1:0] m_bvalid_sync;
    reg [1:0] m_rvalid_sync;

    // Slave side
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s2m_awaddr_reg <= 0;
            s2m_awprot_reg <= 0;
            s2m_awvalid_reg <= 0;
            s2m_wdata_reg <= 0;
            s2m_wstrb_reg <= 0;
            s2m_wvalid_reg <= 0;
            s2m_araddr_reg <= 0;
            s2m_arprot_reg <= 0;
            s2m_arvalid_reg <= 0;
            s_axil_awready <= 0;
            s_axil_wready <= 0;
            s_axil_arready <= 0;
        end else begin
            // AW Channel
            if (s_axil_awvalid && !s2m_awvalid_reg && m_awready_sync[1]) begin
                s2m_awaddr_reg <= s_axil_awaddr;
                s2m_awprot_reg <= s_axil_awprot;
                s2m_awvalid_reg <= 1;
                s_axil_awready <= 1;
            end else if (m_axil_awready) begin
                s2m_awvalid_reg <= 0;
                s_axil_awready <= 0;
            end

            // W Channel
            if (s_axil_wvalid && !s2m_wvalid_reg && m_wready_sync[1]) begin
                s2m_wdata_reg <= s_axil_wdata;
                s2m_wstrb_reg <= s_axil_wstrb;
                s2m_wvalid_reg <= 1;
                s_axil_wready <= 1;
            end else if (m_axil_wready) begin
                s2m_wvalid_reg <= 0;
                s_axil_wready <= 0;
            end

            // AR Channel
            if (s_axil_arvalid && !s2m_arvalid_reg && m_arready_sync[1]) begin
                s2m_araddr_reg <= s_axil_araddr;
                s2m_arprot_reg <= s_axil_arprot;
                s2m_arvalid_reg <= 1;
                s_axil_arready <= 1;
            end else if (m_axil_arready) begin
                s2m_arvalid_reg <= 0;
                s_axil_arready <= 0;
            end
        end
    end

    // Master side
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_awaddr <= 0;
            m_axil_awprot <= 0;
            m_axil_awvalid <= 0;
            m_axil_wdata <= 0;
            m_axil_wstrb <= 0;
            m_axil_wvalid <= 0;
            m_axil_araddr <= 0;
            m_axil_arprot <= 0;
            m_axil_arvalid <= 0;
            m_axil_bready <= 0;
            m_axil_rready <= 0;
            m2s_bresp_reg <= 0;
            m2s_bvalid_reg <= 0;
            m2s_rdata_reg <= 0;
            m2s_rresp_reg <= 0;
            m2s_rvalid_reg <= 0;
        end else begin
            // AW Channel
            if (s2m_awvalid_reg && !m_axil_awvalid && s_awvalid_sync[1]) begin
                m_axil_awaddr <= s2m_awaddr_reg;
                m_axil_awprot <= s2m_awprot_reg;
                m_axil_awvalid <= 1;
            end else if (m_axil_awready) begin
                m_axil_awvalid <= 0;
            end

            // W Channel
            if (s2m_wvalid_reg && !m_axil_wvalid && s_wvalid_sync[1]) begin
                m_axil_wdata <= s2m_wdata_reg;
                m_axil_wstrb <= s2m_wstrb_reg;
                m_axil_wvalid <= 1;
            end else if (m_axil_wready) begin
                m_axil_wvalid <= 0;
            end

            // AR Channel
            if (s2m_arvalid_reg && !m_axil_arvalid && s_arvalid_sync[1]) begin
                m_axil_araddr <= s2m_araddr_reg;
                m_axil_arprot <= s2m_arprot_reg;
                m_axil_arvalid <= 1;
            end else if (m_axil_arready) begin
                m_axil_arvalid <= 0;
            end

            // B Channel
            if (m_axil_bvalid && !m2s_bvalid_reg) begin
                m2s_bresp_reg <= m_axil_bresp;
                m2s_bvalid_reg <= 1;
                m_axil_bready <= 1;
            end else if (s_axil_bready) begin
                m2s_bvalid_reg <= 0;
                m_axil_bready <= 0;
            end

            // R Channel
            if (m_axil_rvalid && !m2s_rvalid_reg) begin
                m2s_rdata_reg <= m_axil_rdata;
                m2s_rresp_reg <= m_axil_rresp;
                m2s_rvalid_reg <= 1;
                m_axil_rready <= 1;
            end else if (s_axil_rready) begin
                m2s_rvalid_reg <= 0;
                m_axil_rready <= 0;
            end
        end
    end

    // Cross-clock domain synchronizers
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_awvalid_sync <= 0;
            s_wvalid_sync <= 0;
            s_arvalid_sync <= 0;
        end else begin
            s_awvalid_sync <= {s_awvalid_sync[0], s2m_awvalid_reg};
            s_wvalid_sync <= {s_wvalid_sync[0], s2m_wvalid_reg};
            s_arvalid_sync <= {s_arvalid_sync[0], s2m_arvalid_reg};
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_awready_sync <= 0;
            m_wready_sync <= 0;
            m_arready_sync <= 0;
            m_bvalid_sync <= 0;
            m_rvalid_sync <= 0;
        end else begin
            m_awready_sync <= {m_awready_sync[0], m_axil_awready};
            m_wready_sync <= {m_wready_sync[0], m_axil_wready};
            m_arready_sync <= {m_arready_sync[0], m_axil_arready};
            m_bvalid_sync <= {m_bvalid_sync[0], m_axil_bvalid};
            m_rvalid_sync <= {m_rvalid_sync[0], m_axil_rvalid};
        end
    end

    // Slave outputs
    assign s_axil_bresp = m2s_bresp_reg;
    assign s_axil_bvalid = m2s_bvalid_reg;
    assign s_axil_rdata = m2s_rdata_reg;
    assign s_axil_rresp = m2s_rresp_reg;
    assign s_axil_rvalid = m2s_rvalid_reg;

    // Master outputs
    assign m_axil_awaddr = s2m_awaddr_reg;
    assign m_axil_awprot = s2m_awprot_reg;
    assign m_axil_awvalid = s2m_awvalid_reg;
    assign m_axil_wdata = s2m_wdata_reg;
    assign m_axil_wstrb = s2m_wstrb_reg;
    assign m_axil_wvalid = s2m_wvalid_reg;
    assign m_axil_araddr = s2m_araddr_reg;
    assign m_axil_arprot = s2m_arprot_reg;
    assign m_axil_arvalid = s2m_arvalid_reg;
    assign m_axil_bready = s_axil_bready;
    assign m_axil_rready = s_axil_rready;

endmodule
