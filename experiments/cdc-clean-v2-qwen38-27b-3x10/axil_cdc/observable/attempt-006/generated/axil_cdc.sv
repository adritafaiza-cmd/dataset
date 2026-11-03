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
    reg [ADDR_WIDTH-1:0] s_awaddr_reg;
    reg [2:0]            s_awprot_reg;
    reg                  s_awvalid_reg;
    reg                  s_awready_reg;

    // Synchronous reset for s domain
    reg [2:0] s_rst_sync;
    always @(posedge s_clk) begin
        s_rst_sync <= {s_rst_sync[1:0], s_rst};
    end
    wire s_rst_synced = s_rst_sync[2];

    // AW handshake in S domain
    wire s_aw_handshake = s_axil_awvalid & s_axil_awready;
    assign s_axil_awready = s_awready_reg;

    always @(posedge s_clk) begin
        if (s_rst_synced) begin
            s_awaddr_reg  <= {ADDR_WIDTH{1'b0}};
            s_awprot_reg  <= 3'b000;
            s_awvalid_reg <= 1'b0;
            s_awready_reg <= 1'b0;
        end else begin
            if (s_axil_awvalid & s_axil_awready) begin
                s_awaddr_reg  <= s_axil_awaddr;
                s_awprot_reg  <= s_axil_awprot;
                s_awvalid_reg <= 1'b1;
                s_awready_reg <= 1'b0;
            end else if (s_awready_reg) begin
                s_awready_reg <= 1'b1;
            end
        end
    end

    // CDC: s_awvalid_reg -> m domain
    reg [2:0] m_s_awvalid_sync;
    always @(posedge m_clk) begin
        m_s_awvalid_sync <= {m_s_awvalid_sync[1:0], s_awvalid_reg};
    end
    wire m_s_awvalid = m_s_awvalid_sync[2];

    // Synchronous reset for m domain
    reg [2:0] m_rst_sync;
    always @(posedge m_clk) begin
        m_rst_sync <= {m_rst_sync[1:0], m_rst};
    end
    wire m_rst_synced = m_rst_sync[2];

    // AW handshake in M domain
    reg m_awvalid_reg;
    assign m_axil_awvalid = m_awvalid_reg;

    always @(posedge m_clk) begin
        if (m_rst_synced) begin
            m_awvalid_reg <= 1'b0;
        end else begin
            if (m_s_awvalid & m_axil_awready) begin
                m_awvalid_reg <= 1'b0;
            end else if (m_s_awvalid) begin
                m_awvalid_reg <= 1'b1;
            end
        end
    end

    // CDC: m_awvalid_reg -> s domain (ack)
    reg [2:0] s_m_awvalid_sync;
    always @(posedge s_clk) begin
        s_m_awvalid_sync <= {s_m_awvalid_sync[1:0], m_awvalid_reg};
    end
    wire s_m_awvalid = s_m_awvalid_sync[2];

    // When m_awvalid goes high then low, it means the handshake happened
    // We need to detect the falling edge of m_awvalid to know the handshake completed
    reg s_m_awvalid_prev;
    always @(posedge s_clk) begin
        if (s_rst_synced) begin
            s_m_awvalid_prev <= 1'b0;
        end else begin
            s_m_awvalid_prev <= s_m_awvalid;
        end
    end
    wire m_aw_handshake_done = s_m_awvalid_prev & ~s_m_awvalid;

    // Update s_awvalid_reg when handshake done
    always @(posedge s_clk) begin
        if (s_rst_synced) begin
            // handled above
        end else if (m_aw_handshake_done) begin
            s_awvalid_reg <= 1'b0;
        end
    end

    // ========================================================================
    // Write Data Channel (W) - S to M
    // ========================================================================
    reg [DATA_WIDTH-1:0] s_wdata_reg;
    reg [STRB_WIDTH-1:0] s_wstrb_reg;
    reg                  s_wvalid_reg;
    reg                  s_wready_reg;

    // W handshake in S domain
    wire s_w_handshake = s_axil_wvalid & s_axil_wready;
    assign s_axil_wready = s_wready_reg;

    always @(posedge s_clk) begin
        if (s_rst_synced) begin
            s_wdata_reg  <= {DATA_WIDTH{1'b0}};
            s_wstrb_reg  <= {STRB_WIDTH{1'b0}};
            s_wvalid_reg <= 1'b0;
            s_wready_reg <= 1'b0;
        end else begin
            if (s_axil_wvalid & s_axil_wready) begin
                s_wdata_reg  <= s_axil_wdata;
                s_wstrb_reg  <= s_axil_wstrb;
                s_wvalid_reg <= 1'b1;
                s_wready_reg <= 1'b0;
            end else if (s_wready_reg) begin
                s_wready_reg <= 1'b1;
            end
        end
    end

    // CDC: s_wvalid_reg -> m domain
    reg [2:0] m_s_wvalid_sync;
    always @(posedge m_clk) begin
        m_s_wvalid_sync <= {m_s_wvalid_sync[1:0], s_wvalid_reg};
    end
    wire m_s_wvalid = m_s_wvalid_sync[2];

    // W handshake in M domain
    reg m_wvalid_reg;
    assign m_axil_wvalid = m_wvalid_reg;

    always @(posedge m_clk) begin
        if (m_rst_synced) begin
            m_wvalid_reg <= 1'b0;
        end else begin
            if (m_s_wvalid & m_axil_wready) begin
                m_wvalid_reg <= 1'b0;
            end else if (m_s_wvalid) begin
                m_wvalid_reg <= 1'b1;
            end
        end
    end

    // CDC: m_wvalid_reg -> s domain (ack)
    reg [2:0] s_m_wvalid_sync;
    always @(posedge s_clk) begin
        s_m_wvalid_sync <= {s_m_wvalid_sync[1:0], m_wvalid_reg};
    end
    wire s_m_wvalid = s_m_wvalid_sync[2];

    reg s_m_wvalid_prev;
    always @(posedge s_clk) begin
        if (s_rst_synced) begin
            s_m_wvalid_prev <= 1'b0;
        end else begin
            s_m_wvalid_prev <= s_m_wvalid;
        end
    end
    wire m_w_handshake_done = s_m_wvalid_prev & ~s_m_wvalid;

    always @(posedge s_clk) begin
        if (s_rst_synced) begin
            // handled above
        end else if (m_w_handshake_done) begin
            s_wvalid_reg <= 1'b0;
        end
    end

    // ========================================================================
    // Write Response Channel (B) - M to S
    // ========================================================================
    reg [1:0] m_bresp_reg;
    reg       m_bvalid_reg;
    reg       m_bready_reg;

    // B handshake in M domain
    wire m_b_handshake = m_axil_bvalid & m_axil_bready;
    assign m_axil_bready = m_bready_reg;

    always @(posedge m_clk) begin
        if (m_rst_synced) begin
            m_bresp_reg  <= 2'b00;
            m_bvalid_reg <= 1'b0;
            m_bready_reg <= 1'b0;
        end else begin
            if (m_axil_bvalid & m_axil_bready) begin
                m_bresp_reg  <= m_axil_bresp;
                m_bvalid_reg <= 1'b1;
                m_bready_reg <= 1'b0;
            end else if (m_bready_reg) begin
                m_bready_reg <= 1'b1;
            end
        end
    end

    // CDC: m_bvalid_reg -> s domain
    reg [2:0] s_m_bvalid_sync;
    always @(posedge s_clk) begin
        s_m_bvalid_sync <= {s_m_bvalid_sync[1:0], m_bvalid_reg};
    end
    wire s_m_bvalid = s_m_bvalid_sync[2];

    // B handshake in S domain
    reg s_bvalid_reg;
    assign s_axil_bvalid = s_bvalid_reg;

    always @(posedge s_clk) begin
        if (s_rst_synced) begin
            s_bvalid_reg <= 1'b0;
        end else begin
            if (s_m_bvalid & s_axil_bready) begin
                s_bvalid_reg <= 1'b0;
            end else if (s_m_bvalid) begin
                s_bvalid_reg <= 1'b1;
            end
        end
    end

    // CDC: s_bvalid_reg -> m domain (ack)
    reg [2:0] m_s_bvalid_sync;
    always @(posedge m_clk) begin
        m_s_bvalid_sync <= {m_s_bvalid_sync[1:0], s_bvalid_reg};
    end
    wire m_s_bvalid = m_s_bvalid_sync[2];

    reg m_s_bvalid_prev;
    always @(posedge m_clk) begin
        if (m_rst_synced) begin
            m_s_bvalid_prev <= 1'b0;
        end else begin
            m_s_bvalid_prev <= m_s_bvalid;
        end
    end
    wire s_b_handshake_done = m_s_bvalid_prev & ~m_s_bvalid;

    always @(posedge m_clk) begin
        if (m_rst_synced) begin
            // handled above
        end else if (s_b_handshake_done) begin
            m_bvalid_reg <= 1'b0;
        end
    end

    // ========================================================================
    // Read Address Channel (AR) - S to M
    // ========================================================================
    reg [ADDR_WIDTH-1:0] s_araddr_reg;
    reg [2:0]            s_arprot_reg;
    reg                  s_arvalid_reg;
    reg                  s_arready_reg;

    // AR handshake in S domain
    wire s_ar_handshake = s_axil_arvalid & s_axil_arready;
    assign s_axil_arready = s_arready_reg;

    always @(posedge s_clk) begin
        if (s_rst_synced) begin
            s_araddr_reg  <= {ADDR_WIDTH{1'b0}};
            s_arprot_reg  <= 3'b000;
            s_arvalid_reg <= 1'b0;
            s_arready_reg <= 1'b0;
        end else begin
            if (s_axil_arvalid & s_axil_arready) begin
                s_araddr_reg  <= s_axil_araddr;
                s_arprot_reg  <= s_axil_arprot;
                s_arvalid_reg <= 1'b1;
                s_arready_reg <= 1'b0;
            end else if (s_arready_reg) begin
                s_arready_reg <= 1'b1;
            end
        end
    end

    // CDC: s_arvalid_reg -> m domain
    reg [2:0] m_s_arvalid_sync;
    always @(posedge m_clk) begin
        m_s_arvalid_sync <= {m_s_arvalid_sync[1:0], s_arvalid_reg};
    end
    wire m_s_arvalid = m_s_arvalid_sync[2];

    // AR handshake in M domain
    reg m_arvalid_reg;
    assign m_axil_arvalid = m_arvalid_reg;

    always @(posedge m_clk) begin
        if (m_rst_synced) begin
            m_arvalid_reg <= 1'b0;
        end else begin
            if (m_s_arvalid & m_axil_arready) begin
                m_arvalid_reg <= 1'b0;
            end else if (m_s_arvalid) begin
                m_arvalid_reg <= 1'b1;
            end
        end
    end

    // CDC: m_arvalid_reg -> s domain (ack)
    reg [2:0] s_m_arvalid_sync;
    always @(posedge s_clk) begin
        s_m_arvalid_sync <= {s_m_arvalid_sync[1:0], m_arvalid_reg};
    end
    wire s_m_arvalid = s_m_arvalid_sync[2];

    reg s_m_arvalid_prev;
    always @(posedge s_clk) begin
        if (s_rst_synced) begin
            s_m_arvalid_prev <= 1'b0;
        end else begin
            s_m_arvalid_prev <= s_m_arvalid;
        end
    end
    wire m_ar_handshake_done = s_m_arvalid_prev & ~s_m_arvalid;

    always @(posedge s_clk) begin
        if (s_rst_synced) begin
            // handled above
        end else if (m_ar_handshake_done) begin
            s_arvalid_reg <= 1'b0;
        end
    end

    // ========================================================================
    // Read Data Channel (R) - M to S
    // ========================================================================
    reg [DATA_WIDTH-1:0] m_rdata_reg;
    reg [1:0]            m_rresp_reg;
    reg                  m_rvalid_reg;
    reg                  m_rready_reg;

    // R handshake in M domain
    wire m_r_handshake = m_axil_rvalid & m_axil_rready;
    assign m_axil_rready = m_rready_reg;

    always @(posedge m_clk) begin
        if (m_rst_synced) begin
            m_rdata_reg  <= {DATA_WIDTH{1'b0}};
            m_rresp_reg  <= 2'b00;
            m_rvalid_reg <= 1'b0;
            m_rready_reg <= 1'b0;
        end else begin
            if (m_axil_rvalid & m_axil_rready) begin
                m_rdata_reg  <= m_axil_rdata;
                m_rresp_reg  <= m_axil_rresp;
                m_rvalid_reg <= 1'b1;
                m_rready_reg <= 1'b0;
            end else if (m_rready_reg) begin
                m_rready_reg <= 1'b1;
            end
        end
    end

    // CDC: m_rvalid_reg -> s domain
    reg [2:0] s_m_rvalid_sync;
    always @(posedge s_clk) begin
        s_m_rvalid_sync <= {s_m_rvalid_sync[1:0], m_rvalid_reg};
    end
    wire s_m_rvalid = s_m_rvalid_sync[2];

    // R handshake in S domain
    reg s_rvalid_reg;
    assign s_axil_rvalid = s_rvalid_reg;

    always @(posedge s_clk) begin
        if (s_rst_synced) begin
            s_rvalid_reg <= 1'b0;
        end else begin
            if (s_m_rvalid & s_axil_rready) begin
                s_rvalid_reg <= 1'b0;
            end else if (s_m_rvalid) begin
                s_rvalid_reg <= 1'b1;
            end
        end
    end

    // CDC: s_rvalid_reg -> m domain (ack)
    reg [2:0] m_s_rvalid_sync;
    always @(posedge m_clk) begin
        m_s_rvalid_sync <= {m_s_rvalid_sync[1:0], s_rvalid_reg};
    end
    wire m_s_rvalid = m_s_rvalid_sync[2];

    reg m_s_rvalid_prev;
    always @(posedge m_clk) begin
        if (m_rst_synced) begin
            m_s_rvalid_prev <= 1'b0;
        end else begin
            m_s_rvalid_prev <= m_s_rvalid;
        end
    end
    wire s_r_handshake_done = m_s_rvalid_prev & ~m_s_rvalid;

    always @(posedge m_clk) begin
        if (m_rst_synced) begin
            // handled above
        end else if (s_r_handshake_done) begin
            m_rvalid_reg <= 1'b0;
        end
    end

    // ========================================================================
    // Output assignments
    // ========================================================================
    assign m_axil_awaddr = s_awaddr_reg;
    assign m_axil_awprot = s_awprot_reg;
    assign m_axil_wdata  = s_wdata_reg;
    assign m_axil_wstrb  = s_wstrb_reg;
    assign m_axil_araddr = s_araddr_reg;
    assign m_axil_arprot = s_arprot_reg;
    assign s_axil_bresp  = m_bresp_reg;
    assign s_axil_rdata  = m_rdata_reg;
    assign s_axil_rresp  = m_rresp_reg;

endmodule
