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

    // Slave to Master Write Channel
    reg [ADDR_WIDTH-1:0] s2m_awaddr_reg;
    reg [2:0] s2m_awprot_reg;
    reg s2m_awvalid_reg;
    reg [DATA_WIDTH-1:0] s2m_wdata_reg;
    reg [STRB_WIDTH-1:0] s2m_wstrb_reg;
    reg s2m_wvalid_reg;
    reg [1:0] s2m_bresp_reg;
    reg s2m_bvalid_reg;

    // Master to Slave Write Channel
    reg [1:0] m2s_bresp_reg;
    reg m2s_bvalid_reg;

    // Slave to Master Read Channel
    reg [ADDR_WIDTH-1:0] s2m_araddr_reg;
    reg [2:0] s2m_arprot_reg;
    reg s2m_arvalid_reg;
    reg [DATA_WIDTH-1:0] s2m_rdata_reg;
    reg [1:0] s2m_rresp_reg;
    reg s2m_rvalid_reg;

    // Master to Slave Read Channel
    reg [DATA_WIDTH-1:0] m2s_rdata_reg;
    reg [1:0] m2s_rresp_reg;
    reg m2s_rvalid_reg;

    // Synchronizers
    reg [1:0] s_awvalid_sync;
    reg [1:0] s_wvalid_sync;
    reg [1:0] s_arvalid_sync;
    reg [1:0] m_awready_sync;
    reg [1:0] m_wready_sync;
    reg [1:0] m_bvalid_sync;
    reg [1:0] m_arready_sync;
    reg [1:0] m_rvalid_sync;

    // Slave Write Channel
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axil_awready <= 0;
            s_axil_wready <= 0;
            s_axil_bresp <= 0;
            s_axil_bvalid <= 0;
            s2m_awvalid_reg <= 0;
            s2m_wvalid_reg <= 0;
        end else begin
            // Synchronize AW and W channels
            s_awvalid_sync <= {s_awvalid_sync[0], s_axil_awvalid};
            s_wvalid_sync <= {s_wvalid_sync[0], s_axil_wvalid};

            if (m_axil_awready && s2m_awvalid_reg) begin
                s2m_awvalid_reg <= 0;
                s_axil_awready <= 1;
            end else if (!s2m_awvalid_reg && s_awvalid_sync[1]) begin
                s2m_awaddr_reg <= s_axil_awaddr;
                s2m_awprot_reg <= s_axil_awprot;
                s2m_awvalid_reg <= 1;
                s_axil_awready <= 0;
            end

            if (m_axil_wready && s2m_wvalid_reg) begin
                s2m_wvalid_reg <= 0;
                s_axil_wready <= 1;
            end else if (!s2m_wvalid_reg && s_wvalid_sync[1]) begin
                s2m_wdata_reg <= s_axil_wdata;
                s2m_wstrb_reg <= s_axil_wstrb;
                s2m_wvalid_reg <= 1;
                s_axil_wready <= 0;
            end

            // Synchronize B channel
            m_bvalid_sync <= {m_bvalid_sync[0], m_axil_bvalid};

            if (m_bvalid_sync[1] && !s_axil_bvalid) begin
                s2m_bresp_reg <= m_axil_bresp;
                s2m_bvalid_reg <= 1;
                m_axil_bready <= 1;
            end else if (s_axil_bvalid && s_axil_bready) begin
                s2m_bvalid_reg <= 0;
                m_axil_bready <= 0;
            end else begin
                m_axil_bready <= 0;
            end

            // Drive B channel outputs
            s_axil_bresp <= s2m_bresp_reg;
            s_axil_bvalid <= s2m_bvalid_reg;
        end
    end

    // Slave Read Channel
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axil_arready <= 0;
            s_axil_rdata <= 0;
            s_axil_rresp <= 0;
            s_axil_rvalid <= 0;
            s2m_arvalid_reg <= 0;
        end else begin
            // Synchronize AR channel
            s_arvalid_sync <= {s_arvalid_sync[0], s_axil_arvalid};

            if (m_axil_arready && s2m_arvalid_reg) begin
                s2m_arvalid_reg <= 0;
                s_axil_arready <= 1;
            end else if (!s2m_arvalid_reg && s_arvalid_sync[1]) begin
                s2m_araddr_reg <= s_axil_araddr;
                s2m_arprot_reg <= s_axil_arprot;
                s2m_arvalid_reg <= 1;
                s_axil_arready <= 0;
            end

            // Synchronize R channel
            m_rvalid_sync <= {m_rvalid_sync[0], m_axil_rvalid};

            if (m_rvalid_sync[1] && !s_axil_rvalid) begin
                s2m_rdata_reg <= m_axil_rdata;
                s2m_rresp_reg <= m_axil_rresp;
                s2m_rvalid_reg <= 1;
                m_axil_rready <= 1;
            end else if (s_axil_rvalid && s_axil_rready) begin
                s2m_rvalid_reg <= 0;
                m_axil_rready <= 0;
            end else begin
                m_axil_rready <= 0;
            end

            // Drive R channel outputs
            s_axil_rdata <= s2m_rdata_reg;
            s_axil_rresp <= s2m_rresp_reg;
            s_axil_rvalid <= s2m_rvalid_reg;
        end
    end

    // Master Write Channel
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_awaddr <= 0;
            m_axil_awprot <= 0;
            m_axil_awvalid <= 0;
            m_axil_wdata <= 0;
            m_axil_wstrb <= 0;
            m_axil_wvalid <= 0;
            m2s_bvalid_reg <= 0;
        end else begin
            // Synchronize AW and W channels
            m_awready_sync <= {m_awready_sync[0], m_axil_awready};
            m_wready_sync <= {m_wready_sync[0], m_axil_wready};

            if (m_awready_sync[1] && !m_axil_awvalid) begin
                m_axil_awaddr <= s2m_awaddr_reg;
                m_axil_awprot <= s2m_awprot_reg;
                m_axil_awvalid <= 1;
            end else if (m_axil_awvalid && m_axil_awready) begin
                m_axil_awvalid <= 0;
            end

            if (m_wready_sync[1] && !m_axil_wvalid) begin
                m_axil_wdata <= s2m_wdata_reg;
                m_axil_wstrb <= s2m_wstrb_reg;
                m_axil_wvalid <= 1;
            end else if (m_axil_wvalid && m_axil_wready) begin
                m_axil_wvalid <= 0;
            end

            // Synchronize B channel
            s2m_bvalid_reg <= m_axil_bvalid;

            if (s2m_bvalid_reg && m_axil_bready) begin
                m2s_bvalid_reg <= 1;
            end else begin
                m2s_bvalid_reg <= 0;
            end
        end
    end

    // Master Read Channel
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_araddr <= 0;
            m_axil_arprot <= 0;
            m_axil_arvalid <= 0;
            m2s_rvalid_reg <= 0;
        end else begin
            // Synchronize AR channel
            m_arready_sync <= {m_arready_sync[0], m_axil_arready};

            if (m_arready_sync[1] && !m_axil_arvalid) begin
                m_axil_araddr <= s2m_araddr_reg;
                m_axil_arprot <= s2m_arprot_reg;
                m_axil_arvalid <= 1;
            end else if (m_axil_arvalid && m_axil_arready) begin
                m_axil_arvalid <= 0;
            end

            // Synchronize R channel
            s2m_rvalid_reg <= m_axil_rvalid;

            if (s2m_rvalid_reg && m_axil_rready) begin
                m2s_rvalid_reg <= 1;
            end else begin
                m2s_rvalid_reg <= 0;
            end
        end
    end

    // Drive Master Write Channel Outputs
    assign m_axil_awaddr = s2m_awaddr_reg;
    assign m_axil_awprot = s2m_awprot_reg;
    assign m_axil_awvalid = s2m_awvalid_reg;
    assign m_axil_wdata = s2m_wdata_reg;
    assign m_axil_wstrb = s2m_wstrb_reg;
    assign m_axil_wvalid = s2m_wvalid_reg;
    assign m_axil_bready = s2m_bvalid_reg;

    // Drive Master Read Channel Outputs
    assign m_axil_araddr = s2m_araddr_reg;
    assign m_axil_arprot = s2m_arprot_reg;
    assign m_axil_arvalid = s2m_arvalid_reg;
    assign m_axil_rready = s2m_rvalid_reg;

endmodule
