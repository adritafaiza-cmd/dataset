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

    // ========================================================================
    // Write Address Channel (AW) - Slave to Master
    // ========================================================================
    reg  [ADDR_WIDTH-1:0] s_awaddr_reg;
    reg  [2:0]            s_awprot_reg;
    reg                   s_awvalid_reg;
    reg                   s_awready_reg;

    // Synchronizer for awready (Master to Slave)
    reg                   m_awready_sync1;
    reg                   m_awready_sync2;
    reg                   m_awready_sync3;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_awready_sync1 <= 1'b0;
            m_awready_sync2 <= 1'b0;
            m_awready_sync3 <= 1'b0;
        end else begin
            m_awready_sync1 <= m_axil_awready;
            m_awready_sync2 <= m_awready_sync1;
            m_awready_sync3 <= m_awready_sync2;
        end
    end

    assign s_axil_awready = m_awready_sync3;

    // Synchronizer for awvalid (Slave to Master)
    reg                   s_awvalid_sync1;
    reg                   s_awvalid_sync2;
    reg                   s_awvalid_sync3;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_awvalid_sync1 <= 1'b0;
            s_awvalid_sync2 <= 1'b0;
            s_awvalid_sync3 <= 1'b0;
        end else begin
            s_awvalid_sync1 <= s_axil_awvalid;
            s_awvalid_sync2 <= s_awvalid_sync1;
            s_awvalid_sync3 <= s_awvalid_sync2;
        end
    end

    // Master side AW logic
    reg                   m_awvalid_reg;
    reg  [ADDR_WIDTH-1:0] m_awaddr_reg;
    reg  [2:0]            m_awprot_reg;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_awvalid_reg <= 1'b0;
            m_awaddr_reg  <= {ADDR_WIDTH{1'b0}};
            m_awprot_reg  <= 3'b000;
        end else begin
            if (m_awvalid_reg && m_axil_awready) begin
                m_awvalid_reg <= 1'b0;
            end else if (!m_awvalid_reg && s_awvalid_sync3) begin
                m_awvalid_reg <= 1'b1;
                m_awaddr_reg  <= s_awaddr_reg;
                m_awprot_reg  <= s_awprot_reg;
            end
        end
    end

    assign m_axil_awvalid = m_awvalid_reg;
    assign m_axil_awaddr  = m_awaddr_reg;
    assign m_axil_awprot  = m_awprot_reg;

    // Slave side AW logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_awvalid_reg <= 1'b0;
            s_awaddr_reg  <= {ADDR_WIDTH{1'b0}};
            s_awprot_reg  <= 3'b000;
        end else begin
            if (s_awvalid_reg && m_awready_sync3) begin
                s_awvalid_reg <= 1'b0;
            end else if (!s_awvalid_reg && s_axil_awvalid) begin
                s_awvalid_reg <= 1'b1;
                s_awaddr_reg  <= s_axil_awaddr;
                s_awprot_reg  <= s_axil_awprot;
            end
        end
    end

    // ========================================================================
    // Write Data Channel (W) - Slave to Master
    // ========================================================================
    reg  [DATA_WIDTH-1:0] s_wdata_reg;
    reg  [STRB_WIDTH-1:0] s_wstrb_reg;
    reg                   s_wvalid_reg;
    reg                   s_wready_reg;

    // Synchronizer for wready (Master to Slave)
    reg                   m_wready_sync1;
    reg                   m_wready_sync2;
    reg                   m_wready_sync3;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_wready_sync1 <= 1'b0;
            m_wready_sync2 <= 1'b0;
            m_wready_sync3 <= 1'b0;
        end else begin
            m_wready_sync1 <= m_axil_wready;
            m_wready_sync2 <= m_wready_sync1;
            m_wready_sync3 <= m_wready_sync2;
        end
    end

    assign s_axil_wready = m_wready_sync3;

    // Synchronizer for wvalid (Slave to Master)
    reg                   s_wvalid_sync1;
    reg                   s_wvalid_sync2;
    reg                   s_wvalid_sync3;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_wvalid_sync1 <= 1'b0;
            s_wvalid_sync2 <= 1'b0;
            s_wvalid_sync3 <= 1'b0;
        end else begin
            s_wvalid_sync1 <= s_axil_wvalid;
            s_wvalid_sync2 <= s_wvalid_sync1;
            s_wvalid_sync3 <= s_wvalid_sync2;
        end
    end

    // Master side W logic
    reg                   m_wvalid_reg;
    reg  [DATA_WIDTH-1:0] m_wdata_reg;
    reg  [STRB_WIDTH-1:0] m_wstrb_reg;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_wvalid_reg <= 1'b0;
            m_wdata_reg  <= {DATA_WIDTH{1'b0}};
            m_wstrb_reg  <= {STRB_WIDTH{1'b0}};
        end else begin
            if (m_wvalid_reg && m_axil_wready) begin
                m_wvalid_reg <= 1'b0;
            end else if (!m_wvalid_reg && s_wvalid_sync3) begin
                m_wvalid_reg <= 1'b1;
                m_wdata_reg  <= s_wdata_reg;
                m_wstrb_reg  <= s_wstrb_reg;
            end
        end
    end

    assign m_axil_wvalid = m_wvalid_reg;
    assign m_axil_wdata  = m_wdata_reg;
    assign m_axil_wstrb  = m_wstrb_reg;

    // Slave side W logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wvalid_reg <= 1'b0;
            s_wdata_reg  <= {DATA_WIDTH{1'b0}};
            s_wstrb_reg  <= {STRB_WIDTH{1'b0}};
        end else begin
            if (s_wvalid_reg && m_wready_sync3) begin
                s_wvalid_reg <= 1'b0;
            end else if (!s_wvalid_reg && s_axil_wvalid) begin
                s_wvalid_reg <= 1'b1;
                s_wdata_reg  <= s_axil_wdata;
                s_wstrb_reg  <= s_axil_wstrb;
            end
        end
    end

    // ========================================================================
    // Write Response Channel (B) - Master to Slave
    // ========================================================================
    reg  [1:0] s_bresp_reg;
    reg        s_bvalid_reg;
    reg        s_bready_reg;

    // Synchronizer for bvalid (Master to Slave)
    reg        m_bvalid_sync1;
    reg        m_bvalid_sync2;
    reg        m_bvalid_sync3;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_bvalid_sync1 <= 1'b0;
            m_bvalid_sync2 <= 1'b0;
            m_bvalid_sync3 <= 1'b0;
        end else begin
            m_bvalid_sync1 <= m_axil_bvalid;
            m_bvalid_sync2 <= m_bvalid_sync1;
            m_bvalid_sync3 <= m_bvalid_sync2;
        end
    end

    // Synchronizer for bready (Slave to Master)
    reg        s_bready_sync1;
    reg        s_bready_sync2;
    reg        s_bready_sync3;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_bready_sync1 <= 1'b0;
            s_bready_sync2 <= 1'b0;
            s_bready_sync3 <= 1'b0;
        end else begin
            s_bready_sync1 <= s_axil_bready;
            s_bready_sync2 <= s_bready_sync1;
            s_bready_sync3 <= s_bready_sync2;
        end
    end

    // Master side B logic
    reg        m_bvalid_reg;
    reg  [1:0] m_bresp_reg;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_bvalid_reg <= 1'b0;
            m_bresp_reg  <= 2'b00;
        end else begin
            if (m_bvalid_reg && s_bready_sync3) begin
                m_bvalid_reg <= 1'b0;
            end else if (!m_bvalid_reg && m_axil_bvalid) begin
                m_bvalid_reg <= 1'b1;
                m_bresp_reg  <= m_axil_bresp;
            end
        end
    end

    assign m_axil_bready = m_bvalid_reg;

    // Slave side B logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_bvalid_reg <= 1'b0;
            s_bresp_reg  <= 2'b00;
        end else begin
            if (s_bvalid_reg && s_axil_bready) begin
                s_bvalid_reg <= 1'b0;
            end else if (!s_bvalid_reg && m_bvalid_sync3) begin
                s_bvalid_reg <= 1'b1;
                s_bresp_reg  <= m_bresp_reg;
            end
        end
    end

    assign s_axil_bvalid = s_bvalid_reg;
    assign s_axil_bresp  = s_bresp_reg;

    // ========================================================================
    // Read Address Channel (AR) - Slave to Master
    // ========================================================================
    reg  [ADDR_WIDTH-1:0] s_araddr_reg;
    reg  [2:0]            s_arprot_reg;
    reg                   s_arvalid_reg;
    reg                   s_arready_reg;

    // Synchronizer for arready (Master to Slave)
    reg                   m_arready_sync1;
    reg                   m_arready_sync2;
    reg                   m_arready_sync3;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_arready_sync1 <= 1'b0;
            m_arready_sync2 <= 1'b0;
            m_arready_sync3 <= 1'b0;
        end else begin
            m_arready_sync1 <= m_axil_arready;
            m_arready_sync2 <= m_arready_sync1;
            m_arready_sync3 <= m_arready_sync2;
        end
    end

    assign s_axil_arready = m_arready_sync3;

    // Synchronizer for arvalid (Slave to Master)
    reg                   s_arvalid_sync1;
    reg                   s_arvalid_sync2;
    reg                   s_arvalid_sync3;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_arvalid_sync1 <= 1'b0;
            s_arvalid_sync2 <= 1'b0;
            s_arvalid_sync3 <= 1'b0;
        end else begin
            s_arvalid_sync1 <= s_axil_arvalid;
            s_arvalid_sync2 <= s_arvalid_sync1;
            s_arvalid_sync3 <= s_arvalid_sync2;
        end
    end

    // Master side AR logic
    reg                   m_arvalid_reg;
    reg  [ADDR_WIDTH-1:0] m_araddr_reg;
    reg  [2:0]            m_arprot_reg;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_arvalid_reg <= 1'b0;
            m_araddr_reg  <= {ADDR_WIDTH{1'b0}};
            m_arprot_reg  <= 3'b000;
        end else begin
            if (m_arvalid_reg && m_axil_arready) begin
                m_arvalid_reg <= 1'b0;
            end else if (!m_arvalid_reg && s_arvalid_sync3) begin
                m_arvalid_reg <= 1'b1;
                m_araddr_reg  <= s_araddr_reg;
                m_arprot_reg  <= s_arprot_reg;
            end
        end
    end

    assign m_axil_arvalid = m_arvalid_reg;
    assign m_axil_araddr  = m_araddr_reg;
    assign m_axil_arprot  = m_arprot_reg;

    // Slave side AR logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_arvalid_reg <= 1'b0;
            s_araddr_reg  <= {ADDR_WIDTH{1'b0}};
            s_arprot_reg  <= 3'b000;
        end else begin
            if (s_arvalid_reg && m_arready_sync3) begin
                s_arvalid_reg <= 1'b0;
            end else if (!s_arvalid_reg && s_axil_arvalid) begin
                s_arvalid_reg <= 1'b1;
                s_araddr_reg  <= s_axil_araddr;
                s_arprot_reg  <= s_axil_arprot;
            end
        end
    end

    // ========================================================================
    // Read Data Channel (R) - Master to Slave
    // ========================================================================
    reg  [DATA_WIDTH-1:0] s_rdata_reg;
    reg  [1:0]            s_rresp_reg;
    reg                   s_rvalid_reg;
    reg                   s_rready_reg;

    // Synchronizer for rvalid (Master to Slave)
    reg        m_rvalid_sync1;
    reg        m_rvalid_sync2;
    reg        m_rvalid_sync3;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_rvalid_sync1 <= 1'b0;
            m_rvalid_sync2 <= 1'b0;
            m_rvalid_sync3 <= 1'b0;
        end else begin
            m_rvalid_sync1 <= m_axil_rvalid;
            m_rvalid_sync2 <= m_rvalid_sync1;
            m_rvalid_sync3 <= m_rvalid_sync2;
        end
    end

    // Synchronizer for rready (Slave to Master)
    reg        s_rready_sync1;
    reg        s_rready_sync2;
    reg        s_rready_sync3;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_rready_sync1 <= 1'b0;
            s_rready_sync2 <= 1'b0;
            s_rready_sync3 <= 1'b0;
        end else begin
            s_rready_sync1 <= s_axil_rready;
            s_rready_sync2 <= s_rready_sync1;
            s_rready_sync3 <= s_rready_sync2;
        end
    end

    // Master side R logic
    reg                   m_rvalid_reg;
    reg  [DATA_WIDTH-1:0] m_rdata_reg;
    reg  [1:0]            m_rresp_reg;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rvalid_reg <= 1'b0;
            m_rdata_reg  <= {DATA_WIDTH{1'b0}};
            m_rresp_reg  <= 2'b00;
        end else begin
            if (m_rvalid_reg && s_rready_sync3) begin
                m_rvalid_reg <= 1'b0;
            end else if (!m_rvalid_reg && m_axil_rvalid) begin
                m_rvalid_reg <= 1'b1;
                m_rdata_reg  <= m_axil_rdata;
                m_rresp_reg  <= m_axil_rresp;
            end
        end
    end

    assign m_axil_rready = m_rvalid_reg;

    // Slave side R logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_rvalid_reg <= 1'b0;
            s_rdata_reg  <= {DATA_WIDTH{1'b0}};
            s_rresp_reg  <= 2'b00;
        end else begin
            if (s_rvalid_reg && s_axil_rready) begin
                s_rvalid_reg <= 1'b0;
            end else if (!s_rvalid_reg && m_rvalid_sync3) begin
                s_rvalid_reg <= 1'b1;
                s_rdata_reg  <= m_rdata_reg;
                s_rresp_reg  <= m_rresp_reg;
            end
        end
    end

    assign s_axil_rvalid = s_rvalid_reg;
    assign s_axil_rdata  = s_rdata_reg;
    assign s_axil_rresp  = s_rresp_reg;

endmodule
