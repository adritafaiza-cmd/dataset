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
    // Write Address Channel (AW) - S to M
    // ========================================================================
    reg  [ADDR_WIDTH-1:0] s_awaddr_reg;
    reg  [2:0]            s_awprot_reg;
    reg                   s_aw_valid_reg;
    reg                   s_aw_ready_reg;

    wire s_aw_handshake = s_axil_awvalid & s_axil_awready;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_awaddr_reg   <= {ADDR_WIDTH{1'b0}};
            s_awprot_reg   <= 3'b000;
            s_aw_valid_reg <= 1'b0;
            s_aw_ready_reg <= 1'b0;
        end else begin
            if (s_aw_handshake) begin
                s_awaddr_reg   <= s_axil_awaddr;
                s_awprot_reg   <= s_axil_awprot;
                s_aw_valid_reg <= 1'b1;
            end else if (s_aw_valid_reg & s_aw_ready_reg) begin
                s_aw_valid_reg <= 1'b0;
            end
        end
    end

    assign s_axil_awready = s_aw_ready_reg;

    // AW CDC: S to M
    reg  [ADDR_WIDTH-1:0] m_awaddr_reg;
    reg  [2:0]            m_awprot_reg;
    reg                   m_aw_valid_reg;
    reg                   m_aw_ready_reg;

    // Synchronizers for AW valid
    reg s_aw_valid_sync1, s_aw_valid_sync2;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_aw_valid_sync1 <= 1'b0;
            s_aw_valid_sync2 <= 1'b0;
        end else begin
            s_aw_valid_sync1 <= s_aw_valid_reg;
            s_aw_valid_sync2 <= s_aw_valid_sync1;
        end
    end

    // Synchronizers for AW ready
    reg m_aw_ready_sync1, m_aw_ready_sync2;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_aw_ready_sync1 <= 1'b0;
            m_aw_ready_sync2 <= 1'b0;
        end else begin
            m_aw_ready_sync1 <= m_aw_ready_reg;
            m_aw_ready_sync2 <= m_aw_ready_sync1;
        end
    end

    // M-side AW logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_awaddr_reg   <= {ADDR_WIDTH{1'b0}};
            m_awprot_reg   <= 3'b000;
            m_aw_valid_reg <= 1'b0;
            m_aw_ready_reg <= 1'b0;
        end else begin
            if (s_aw_valid_sync2 & ~m_aw_valid_reg) begin
                m_awaddr_reg   <= s_awaddr_reg;
                m_awprot_reg   <= s_awprot_reg;
                m_aw_valid_reg <= 1'b1;
            end else if (m_aw_valid_reg & m_axil_awready) begin
                m_aw_valid_reg <= 1'b0;
            end
            m_aw_ready_reg <= s_aw_valid_sync2;
        end
    end

    assign m_axil_awaddr  = m_awaddr_reg;
    assign m_axil_awprot  = m_awprot_reg;
    assign m_axil_awvalid = m_aw_valid_reg;

    // ========================================================================
    // Write Data Channel (W) - S to M
    // ========================================================================
    reg  [DATA_WIDTH-1:0] s_wdata_reg;
    reg  [STRB_WIDTH-1:0] s_wstrb_reg;
    reg                   s_w_valid_reg;
    reg                   s_w_ready_reg;

    wire s_w_handshake = s_axil_wvalid & s_axil_wready;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wdata_reg   <= {DATA_WIDTH{1'b0}};
            s_wstrb_reg   <= {STRB_WIDTH{1'b0}};
            s_w_valid_reg <= 1'b0;
            s_w_ready_reg <= 1'b0;
        end else begin
            if (s_w_handshake) begin
                s_wdata_reg   <= s_axil_wdata;
                s_wstrb_reg   <= s_axil_wstrb;
                s_w_valid_reg <= 1'b1;
            end else if (s_w_valid_reg & s_w_ready_reg) begin
                s_w_valid_reg <= 1'b0;
            end
        end
    end

    assign s_axil_wready = s_w_ready_reg;

    // W CDC: S to M
    reg  [DATA_WIDTH-1:0] m_wdata_reg;
    reg  [STRB_WIDTH-1:0] m_wstrb_reg;
    reg                   m_w_valid_reg;
    reg                   m_w_ready_reg;

    // Synchronizers for W valid
    reg s_w_valid_sync1, s_w_valid_sync2;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_w_valid_sync1 <= 1'b0;
            s_w_valid_sync2 <= 1'b0;
        end else begin
            s_w_valid_sync1 <= s_w_valid_reg;
            s_w_valid_sync2 <= s_w_valid_sync1;
        end
    end

    // Synchronizers for W ready
    reg m_w_ready_sync1, m_w_ready_sync2;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_w_ready_sync1 <= 1'b0;
            m_w_ready_sync2 <= 1'b0;
        end else begin
            m_w_ready_sync1 <= m_w_ready_reg;
            m_w_ready_sync2 <= m_w_ready_sync1;
        end
    end

    // M-side W logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_wdata_reg   <= {DATA_WIDTH{1'b0}};
            m_wstrb_reg   <= {STRB_WIDTH{1'b0}};
            m_w_valid_reg <= 1'b0;
            m_w_ready_reg <= 1'b0;
        end else begin
            if (s_w_valid_sync2 & ~m_w_valid_reg) begin
                m_wdata_reg   <= s_wdata_reg;
                m_wstrb_reg   <= s_wstrb_reg;
                m_w_valid_reg <= 1'b1;
            end else if (m_w_valid_reg & m_axil_wready) begin
                m_w_valid_reg <= 1'b0;
            end
            m_w_ready_reg <= s_w_valid_sync2;
        end
    end

    assign m_axil_wdata  = m_wdata_reg;
    assign m_axil_wstrb  = m_wstrb_reg;
    assign m_axil_wvalid = m_w_valid_reg;

    // ========================================================================
    // Write Response Channel (B) - M to S
    // ========================================================================
    reg  [1:0] s_bresp_reg;
    reg        s_bvalid_reg;
    reg        s_bready_reg;

    wire s_b_handshake = s_axil_bvalid & s_axil_bready;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_bresp_reg  <= 2'b00;
            s_bvalid_reg <= 1'b0;
            s_bready_reg <= 1'b0;
        end else begin
            if (s_bvalid_reg & s_bready_reg) begin
                s_bvalid_reg <= 1'b0;
            end else if (s_bvalid_reg & ~s_bready_reg) begin
                // Hold
            end else if (~s_bvalid_reg & s_bready_reg) begin
                s_bresp_reg  <= m_bresp_reg;
                s_bvalid_reg <= 1'b1;
            end
        end
    end

    assign s_axil_bresp  = s_bresp_reg;
    assign s_axil_bvalid = s_bvalid_reg;

    // B CDC: M to S
    reg  [1:0] m_bresp_reg;
    reg        m_bvalid_reg;
    reg        m_bready_reg;

    // Synchronizers for B valid
    reg m_bvalid_sync1, m_bvalid_sync2;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_bvalid_sync1 <= 1'b0;
            m_bvalid_sync2 <= 1'b0;
        end else begin
            m_bvalid_sync1 <= m_bvalid_reg;
            m_bvalid_sync2 <= m_bvalid_sync1;
        end
    end

    // Synchronizers for B ready
    reg s_bready_sync1, s_bready_sync2;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_bready_sync1 <= 1'b0;
            s_bready_sync2 <= 1'b0;
        end else begin
            s_bready_sync1 <= s_bready_reg;
            s_bready_sync2 <= s_bready_sync1;
        end
    end

    // M-side B logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_bresp_reg  <= 2'b00;
            m_bvalid_reg <= 1'b0;
            m_bready_reg <= 1'b0;
        end else begin
            if (m_axil_bvalid & ~m_bvalid_reg) begin
                m_bresp_reg  <= m_axil_bresp;
                m_bvalid_reg <= 1'b1;
            end else if (m_bvalid_reg & s_bready_sync2) begin
                m_bvalid_reg <= 1'b0;
            end
            m_bready_reg <= s_bready_sync2;
        end
    end

    assign m_axil_bready = m_bready_reg;

    // ========================================================================
    // Read Address Channel (AR) - S to M
    // ========================================================================
    reg  [ADDR_WIDTH-1:0] s_araddr_reg;
    reg  [2:0]            s_arprot_reg;
    reg                   s_ar_valid_reg;
    reg                   s_ar_ready_reg;

    wire s_ar_handshake = s_axil_arvalid & s_axil_arready;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_araddr_reg   <= {ADDR_WIDTH{1'b0}};
            s_arprot_reg   <= 3'b000;
            s_ar_valid_reg <= 1'b0;
            s_ar_ready_reg <= 1'b0;
        end else begin
            if (s_ar_handshake) begin
                s_araddr_reg   <= s_axil_araddr;
                s_arprot_reg   <= s_axil_arprot;
                s_ar_valid_reg <= 1'b1;
            end else if (s_ar_valid_reg & s_ar_ready_reg) begin
                s_ar_valid_reg <= 1'b0;
            end
        end
    end

    assign s_axil_arready = s_ar_ready_reg;

    // AR CDC: S to M
    reg  [ADDR_WIDTH-1:0] m_araddr_reg;
    reg  [2:0]            m_arprot_reg;
    reg                   m_ar_valid_reg;
    reg                   m_ar_ready_reg;

    // Synchronizers for AR valid
    reg s_ar_valid_sync1, s_ar_valid_sync2;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_ar_valid_sync1 <= 1'b0;
            s_ar_valid_sync2 <= 1'b0;
        end else begin
            s_ar_valid_sync1 <= s_ar_valid_reg;
            s_ar_valid_sync2 <= s_ar_valid_sync1;
        end
    end

    // Synchronizers for AR ready
    reg m_ar_ready_sync1, m_ar_ready_sync2;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_ar_ready_sync1 <= 1'b0;
            m_ar_ready_sync2 <= 1'b0;
        end else begin
            m_ar_ready_sync1 <= m_ar_ready_reg;
            m_ar_ready_sync2 <= m_ar_ready_sync1;
        end
    end

    // M-side AR logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_araddr_reg   <= {ADDR_WIDTH{1'b0}};
            m_arprot_reg   <= 3'b000;
            m_ar_valid_reg <= 1'b0;
            m_ar_ready_reg <= 1'b0;
        end else begin
            if (s_ar_valid_sync2 & ~m_ar_valid_reg) begin
                m_araddr_reg   <= s_araddr_reg;
                m_arprot_reg   <= s_arprot_reg;
                m_ar_valid_reg <= 1'b1;
            end else if (m_ar_valid_reg & m_axil_arready) begin
                m_ar_valid_reg <= 1'b0;
            end
            m_ar_ready_reg <= s_ar_valid_sync2;
        end
    end

    assign m_axil_araddr  = m_araddr_reg;
    assign m_axil_arprot  = m_arprot_reg;
    assign m_axil_arvalid = m_ar_valid_reg;

    // ========================================================================
    // Read Data Channel (R) - M to S
    // ========================================================================
    reg  [DATA_WIDTH-1:0] s_rdata_reg;
    reg  [1:0]            s_rresp_reg;
    reg                   s_rvalid_reg;
    reg                   s_rready_reg;

    wire s_r_handshake = s_axil_rvalid & s_axil_rready;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_rdata_reg  <= {DATA_WIDTH{1'b0}};
            s_rresp_reg  <= 2'b00;
            s_rvalid_reg <= 1'b0;
            s_rready_reg <= 1'b0;
        end else begin
            if (s_rvalid_reg & s_rready_reg) begin
                s_rvalid_reg <= 1'b0;
            end else if (s_rvalid_reg & ~s_rready_reg) begin
                // Hold
            end else if (~s_rvalid_reg & s_rready_reg) begin
                s_rdata_reg  <= m_rdata_reg;
                s_rresp_reg  <= m_rresp_reg;
                s_rvalid_reg <= 1'b1;
            end
        end
    end

    assign s_axil_rdata  = s_rdata_reg;
    assign s_axil_rresp  = s_rresp_reg;
    assign s_axil_rvalid = s_rvalid_reg;

    // R CDC: M to S
    reg  [DATA_WIDTH-1:0] m_rdata_reg;
    reg  [1:0]            m_rresp_reg;
    reg                   m_rvalid_reg;
    reg                   m_rready_reg;

    // Synchronizers for R valid
    reg m_rvalid_sync1, m_rvalid_sync2;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_rvalid_sync1 <= 1'b0;
            m_rvalid_sync2 <= 1'b0;
        end else begin
            m_rvalid_sync1 <= m_rvalid_reg;
            m_rvalid_sync2 <= m_rvalid_sync1;
        end
    end

    // Synchronizers for R ready
    reg s_rready_sync1, s_rready_sync2;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_rready_sync1 <= 1'b0;
            s_rready_sync2 <= 1'b0;
        end else begin
            s_rready_sync1 <= s_rready_reg;
            s_rready_sync2 <= s_rready_sync1;
        end
    end

    // M-side R logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rdata_reg  <= {DATA_WIDTH{1'b0}};
            m_rresp_reg  <= 2'b00;
            m_rvalid_reg <= 1'b0;
            m_rready_reg <= 1'b0;
        end else begin
            if (m_axil_rvalid & ~m_rvalid_reg) begin
                m_rdata_reg  <= m_axil_rdata;
                m_rresp_reg  <= m_axil_rresp;
                m_rvalid_reg <= 1'b1;
            end else if (m_rvalid_reg & s_rready_sync2) begin
                m_rvalid_reg <= 1'b0;
            end
            m_rready_reg <= s_rready_sync2;
        end
    end

    assign m_axil_rready = m_rready_reg;

endmodule
