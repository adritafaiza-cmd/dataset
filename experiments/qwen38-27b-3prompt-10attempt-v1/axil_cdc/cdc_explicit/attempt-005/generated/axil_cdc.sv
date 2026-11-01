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
    // Internal signals
    // ========================================================================

    // Write channel: S -> M
    wire [ADDR_WIDTH-1:0] s2m_awaddr;
    wire [2:0]            s2m_awprot;
    wire                  s2m_awvalid;
    wire                  m2s_awready;

    wire [DATA_WIDTH-1:0] s2m_wdata;
    wire [STRB_WIDTH-1:0] s2m_wstrb;
    wire                  s2m_wvalid;
    wire                  m2s_wready;

    // Write response: M -> S
    wire [1:0]            m2s_bresp;
    wire                  m2s_bvalid;
    wire                  s2m_bready;

    // Read channel: S -> M
    wire [ADDR_WIDTH-1:0] s2m_araddr;
    wire [2:0]            s2m_arprot;
    wire                  s2m_arvalid;
    wire                  m2s_arready;

    // Read response: M -> S
    wire [DATA_WIDTH-1:0] m2s_rdata;
    wire [1:0]            m2s_rresp;
    wire                  m2s_rvalid;
    wire                  s2m_rready;

    // ========================================================================
    // Write Address Channel: S -> M (data + valid)
    // ========================================================================

    // S-side: capture AW when valid and not busy
    reg  [ADDR_WIDTH-1:0] s_awaddr_reg;
    reg  [2:0]            s_awprot_reg;
    reg                   s_aw_pending;

    wire s_aw_fire = s_axil_awvalid && s_axil_awready;

    assign s_axil_awready = !s_aw_pending;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_aw_pending <= 1'b0;
            s_awaddr_reg <= {ADDR_WIDTH{1'b0}};
            s_awprot_reg <= 3'b000;
        end else begin
            if (s_aw_fire) begin
                s_aw_pending <= 1'b1;
                s_awaddr_reg <= s_axil_awaddr;
                s_awprot_reg <= s_axil_awprot;
            end else if (m2s_awready) begin
                s_aw_pending <= 1'b0;
            end
        end
    end

    // S-side: pulse to M when AW is pending
    reg s_aw_pulse;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_aw_pulse <= 1'b0;
        else
            s_aw_pulse <= s_aw_pending;
    end

    // M-side: receive AW pulse and data
    reg  [ADDR_WIDTH-1:0] m_awaddr_reg;
    reg  [2:0]            m_awprot_reg;
    reg                   m_aw_valid;

    // Synchronizer for AW pulse
    reg [2:0] aw_pulse_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            aw_pulse_sync <= 3'b000;
        else
            aw_pulse_sync <= {aw_pulse_sync[1:0], s_aw_pulse};
    end

    wire m_aw_pulse = aw_pulse_sync[2] & ~aw_pulse_sync[1];

    // Synchronizer for AW data (multi-bit, use handshake-style sync)
    // Since we use a pulse, we need to ensure data is stable.
    // Use a 2-stage synchronizer for each bit of data, but this is unsafe for multi-bit.
    // Instead, use a proper CDC for multi-bit data with a valid/ready handshake.

    // Let's use a different approach: use a FIFO-like CDC with valid/ready.
    // For simplicity and correctness, use a 2-stage synchronizer for the pulse,
    // and capture the data on the M side when the pulse is detected.
    // But multi-bit data crossing requires care.

    // Better approach: Use a CDC module that handles multi-bit data safely.
    // We'll implement a simple CDC using a 2-stage synchronizer for the valid signal,
    // and use the valid signal to latch the data on the receiving side.

    // For AW channel:
    // S-side: s_aw_pulse is a level signal (high while pending)
    // M-side: synchronize s_aw_pulse, detect rising edge, latch data

    // Synchronize the data bits using a 2-stage synchronizer per bit is not safe.
    // Instead, we use the following method:
    // 1. S-side: when s_aw_pending goes high, the data is stable.
    // 2. M-side: synchronize s_aw_pending (level), when it goes high, latch the data.
    //    But the data must be stable during the synchronization.

    // Since s_aw_pending is a level signal that stays high until m2s_awready,
    // we can synchronize it as a level, and when the synchronized version goes high,
    // we latch the data. The data is stable because s_aw_pending is high.

    // Synchronize s_aw_pending as a level
    reg [2:0] aw_valid_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            aw_valid_sync <= 3'b000;
        else
            aw_valid_sync <= {aw_valid_sync[1:0], s_aw_pending};
    end

    wire m_aw_valid_sync = aw_valid_sync[2];

    // Detect rising edge of m_aw_valid_sync
    reg m_aw_valid_sync_prev;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_aw_valid_sync_prev <= 1'b0;
        else
            m_aw_valid_sync_prev <= m_aw_valid_sync;
    end

    wire m_aw_rise = m_aw_valid_sync & ~m_aw_valid_sync_prev;

    // Latch data on rising edge
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_awaddr_reg <= {ADDR_WIDTH{1'b0}};
            m_awprot_reg <= 3'b000;
            m_aw_valid   <= 1'b0;
        end else begin
            if (m_aw_rise) begin
                m_awaddr_reg <= s_awaddr_reg;
                m_awprot_reg <= s_awprot_reg;
                m_aw_valid   <= 1'b1;
            end else if (m_axil_awready) begin
                m_aw_valid   <= 1'b0;
            end
        end
    end

    assign m_axil_awaddr  = m_awaddr_reg;
    assign m_axil_awprot  = m_awprot_reg;
    assign m_axil_awvalid = m_aw_valid;

    // M-side: AW ready back to S
    // Synchronize m_axil_awready to S domain
    reg [2:0] aw_ready_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            aw_ready_sync <= 3'b000;
        else
            aw_ready_sync <= {aw_ready_sync[1:0], m_axil_awready};
    end

    assign m2s_awready = aw_ready_sync[2];

    // ========================================================================
    // Write Data Channel: S -> M (data + valid)
    // ========================================================================

    reg  [DATA_WIDTH-1:0] s_wdata_reg;
    reg  [STRB_WIDTH-1:0] s_wstrb_reg;
    reg                   s_w_pending;

    wire s_w_fire = s_axil_wvalid && s_axil_wready;

    assign s_axil_wready = !s_w_pending;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_w_pending <= 1'b0;
            s_wdata_reg <= {DATA_WIDTH{1'b0}};
            s_wstrb_reg <= {STRB_WIDTH{1'b0}};
        end else begin
            if (s_w_fire) begin
                s_w_pending <= 1'b1;
                s_wdata_reg <= s_axil_wdata;
                s_wstrb_reg <= s_axil_wstrb;
            end else if (m2s_wready) begin
                s_w_pending <= 1'b0;
            end
        end
    end

    // Synchronize s_w_pending to M domain
    reg [2:0] w_valid_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            w_valid_sync <= 3'b000;
        else
            w_valid_sync <= {w_valid_sync[1:0], s_w_pending};
    end

    wire m_w_valid_sync = w_valid_sync[2];

    reg m_w_valid_sync_prev;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_w_valid_sync_prev <= 1'b0;
        else
            m_w_valid_sync_prev <= m_w_valid_sync;
    end

    wire m_w_rise = m_w_valid_sync & ~m_w_valid_sync_prev;

    reg  [DATA_WIDTH-1:0] m_wdata_reg;
    reg  [STRB_WIDTH-1:0] m_wstrb_reg;
    reg                   m_w_valid;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_wdata_reg <= {DATA_WIDTH{1'b0}};
            m_wstrb_reg <= {STRB_WIDTH{1'b0}};
            m_w_valid   <= 1'b0;
        end else begin
            if (m_w_rise) begin
                m_wdata_reg <= s_wdata_reg;
                m_wstrb_reg <= s_wstrb_reg;
                m_w_valid   <= 1'b1;
            end else if (m_axil_wready) begin
                m_w_valid   <= 1'b0;
            end
        end
    end

    assign m_axil_wdata  = m_wdata_reg;
    assign m_axil_wstrb  = m_wstrb_reg;
    assign m_axil_wvalid = m_w_valid;

    // Synchronize m_axil_wready to S domain
    reg [2:0] w_ready_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            w_ready_sync <= 3'b000;
        else
            w_ready_sync <= {w_ready_sync[1:0], m_axil_wready};
    end

    assign m2s_wready = w_ready_sync[2];

    // ========================================================================
    // Write Response Channel: M -> S (data + valid)
    // ========================================================================

    reg  [1:0]            m_bresp_reg;
    reg                   m_b_valid;

    wire m_b_fire = m_axil_bvalid && m_axil_bready;

    assign m_axil_bready = !m_b_valid;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_b_valid   <= 1'b0;
            m_bresp_reg <= 2'b00;
        end else begin
            if (m_b_fire) begin
                m_b_valid   <= 1'b1;
                m_bresp_reg <= m_axil_bresp;
            end else if (s2m_bready) begin
                m_b_valid   <= 1'b0;
            end
        end
    end

    // Synchronize m_b_valid to S domain
    reg [2:0] b_valid_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            b_valid_sync <= 3'b000;
        else
            b_valid_sync <= {b_valid_sync[1:0], m_b_valid};
    end

    wire s_b_valid_sync = b_valid_sync[2];

    reg s_b_valid_sync_prev;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_b_valid_sync_prev <= 1'b0;
        else
            s_b_valid_sync_prev <= s_b_valid_sync;
    end

    wire s_b_rise = s_b_valid_sync & ~s_b_valid_sync_prev;

    reg  [1:0]            s_bresp_reg;
    reg                   s_b_valid;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_b_valid   <= 1'b0;
            s_bresp_reg <= 2'b00;
        end else begin
            if (s_b_rise) begin
                s_b_valid   <= 1'b1;
                s_bresp_reg <= m_bresp_reg;
            end else if (s_axil_bready) begin
                s_b_valid   <= 1'b0;
            end
        end
    end

    assign s_axil_bresp  = s_bresp_reg;
    assign s_axil_bvalid = s_b_valid;

    // Synchronize s_axil_bready to M domain
    reg [2:0] b_ready_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            b_ready_sync <= 3'b000;
        else
            b_ready_sync <= {b_ready_sync[1:0], s_axil_bready};
    end

    assign s2m_bready = b_ready_sync[2];

    // ========================================================================
    // Read Address Channel: S -> M (data + valid)
    // ========================================================================

    reg  [ADDR_WIDTH-1:0] s_araddr_reg;
    reg  [2:0]            s_arprot_reg;
    reg                   s_ar_pending;

    wire s_ar_fire = s_axil_arvalid && s_axil_arready;

    assign s_axil_arready = !s_ar_pending;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_ar_pending <= 1'b0;
            s_araddr_reg <= {ADDR_WIDTH{1'b0}};
            s_arprot_reg <= 3'b000;
        end else begin
            if (s_ar_fire) begin
                s_ar_pending <= 1'b1;
                s_araddr_reg <= s_axil_araddr;
                s_arprot_reg <= s_axil_arprot;
            end else if (m2s_arready) begin
                s_ar_pending <= 1'b0;
            end
        end
    end

    // Synchronize s_ar_pending to M domain
    reg [2:0] ar_valid_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            ar_valid_sync <= 3'b000;
        else
            ar_valid_sync <= {ar_valid_sync[1:0], s_ar_pending};
    end

    wire m_ar_valid_sync = ar_valid_sync[2];

    reg m_ar_valid_sync_prev;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_ar_valid_sync_prev <= 1'b0;
        else
            m_ar_valid_sync_prev <= m_ar_valid_sync;
    end

    wire m_ar_rise = m_ar_valid_sync & ~m_ar_valid_sync_prev;

    reg  [ADDR_WIDTH-1:0] m_araddr_reg;
    reg  [2:0]            m_arprot_reg;
    reg                   m_ar_valid;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_araddr_reg <= {ADDR_WIDTH{1'b0}};
            m_arprot_reg <= 3'b000;
            m_ar_valid   <= 1'b0;
        end else begin
            if (m_ar_rise) begin
                m_araddr_reg <= s_araddr_reg;
                m_arprot_reg <= s_arprot_reg;
                m_ar_valid   <= 1'b1;
            end else if (m_axil_arready) begin
                m_ar_valid   <= 1'b0;
            end
        end
    end

    assign m_axil_araddr  = m_araddr_reg;
    assign m_axil_arprot  = m_arprot_reg;
    assign m_axil_arvalid = m_ar_valid;

    // Synchronize m_axil_arready to S domain
    reg [2:0] ar_ready_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            ar_ready_sync <= 3'b000;
        else
            ar_ready_sync <= {ar_ready_sync[1:0], m_axil_arready};
    end

    assign m2s_arready = ar_ready_sync[2];

    // ========================================================================
    // Read Response Channel: M -> S (data + valid)
    // ========================================================================

    reg  [DATA_WIDTH-1:0] m_rdata_reg;
    reg  [1:0]            m_rresp_reg;
    reg                   m_r_valid;

    wire m_r_fire = m_axil_rvalid && m_axil_rready;

    assign m_axil_rready = !m_r_valid;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_r_valid   <= 1'b0;
            m_rdata_reg <= {DATA_WIDTH{1'b0}};
            m_rresp_reg <= 2'b00;
        end else begin
            if (m_r_fire) begin
                m_r_valid   <= 1'b1;
                m_rdata_reg <= m_axil_rdata;
                m_rresp_reg <= m_axil_rresp;
            end else if (s2m_rready) begin
                m_r_valid   <= 1'b0;
            end
        end
    end

    // Synchronize m_r_valid to S domain
    reg [2:0] r_valid_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            r_valid_sync <= 3'b000;
        else
            r_valid_sync <= {r_valid_sync[1:0], m_r_valid};
    end

    wire s_r_valid_sync = r_valid_sync[2];

    reg s_r_valid_sync_prev;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_r_valid_sync_prev <= 1'b0;
        else
            s_r_valid_sync_prev <= s_r_valid_sync;
    end

    wire s_r_rise = s_r_valid_sync & ~s_r_valid_sync_prev;

    reg  [DATA_WIDTH-1:0] s_rdata_reg;
    reg  [1:0]            s_rresp_reg;
    reg                   s_r_valid;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_r_valid   <= 1'b0;
            s_rdata_reg <= {DATA_WIDTH{1'b0}};
            s_rresp_reg <= 2'b00;
        end else begin
            if (s_r_rise) begin
                s_r_valid   <= 1'b1;
                s_rdata_reg <= m_rdata_reg;
                s_rresp_reg <= m_rresp_reg;
            end else if (s_axil_rready) begin
                s_r_valid   <= 1'b0;
            end
        end
    end

    assign s_axil_rdata  = s_rdata_reg;
    assign s_axil_rresp  = s_rresp_reg;
    assign s_axil_rvalid = s_r_valid;

    // Synchronize s_axil_rready to M domain
    reg [2:0] r_ready_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            r_ready_sync <= 3'b000;
        else
            r_ready_sync <= {r_ready_sync[1:0], s_axil_rready};
    end

    assign s2m_rready = r_ready_sync[2];

endmodule
