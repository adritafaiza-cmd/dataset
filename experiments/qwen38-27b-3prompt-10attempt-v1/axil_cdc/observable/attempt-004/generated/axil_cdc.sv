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
    reg [ADDR_WIDTH-1:0] s_awaddr_reg;
    reg [2:0]            s_awprot_reg;
    reg                  s_awvalid_reg;
    reg                  s_awready_reg;

    // Synchronizer for s_awvalid_reg (S -> M)
    reg [2:0] s_awvalid_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            s_awvalid_sync <= 3'b000;
        else
            s_awvalid_sync <= {s_awvalid_sync[1:0], s_awvalid_reg};
    end
    wire m_s_awvalid = s_awvalid_sync[2];

    // Synchronizer for s_awready_reg (M -> S)
    reg [2:0] s_awready_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_awready_sync <= 3'b000;
        else
            s_awready_sync <= {s_awready_sync[1:0], s_awready_reg};
    end
    wire s_s_awready = s_awready_sync[2];

    // S-domain: AW handshake
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_awaddr_reg  <= {ADDR_WIDTH{1'b0}};
            s_awprot_reg  <= 3'b000;
            s_awvalid_reg <= 1'b0;
            s_awready_reg <= 1'b0;
        end else begin
            if (s_axil_awvalid && s_s_awready) begin
                s_awaddr_reg  <= s_axil_awaddr;
                s_awprot_reg  <= s_axil_awprot;
                s_awvalid_reg <= 1'b1;
            end else if (m_s_awvalid && s_awready_reg) begin
                s_awvalid_reg <= 1'b0;
            end
            if (m_s_awvalid) begin
                s_awready_reg <= 1'b1;
            end else if (s_axil_awvalid && s_s_awready) begin
                s_awready_reg <= 1'b0;
            end
        end
    end

    assign s_axil_awready = s_s_awready;

    // M-domain: AW output
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_awaddr  <= {ADDR_WIDTH{1'b0}};
            m_axil_awprot  <= 3'b000;
            m_axil_awvalid <= 1'b0;
        end else begin
            if (m_s_awvalid) begin
                m_axil_awaddr  <= s_awaddr_reg;
                m_axil_awprot  <= s_awprot_reg;
                m_axil_awvalid <= 1'b1;
            end else if (m_axil_awready) begin
                m_axil_awvalid <= 1'b0;
            end
        end
    end

    // ========================================================================
    // Write Data Channel (W) - Slave to Master
    // ========================================================================
    reg [DATA_WIDTH-1:0] s_wdata_reg;
    reg [STRB_WIDTH-1:0] s_wstrb_reg;
    reg                  s_wvalid_reg;
    reg                  s_wready_reg;

    // Synchronizer for s_wvalid_reg (S -> M)
    reg [2:0] s_wvalid_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            s_wvalid_sync <= 3'b000;
        else
            s_wvalid_sync <= {s_wvalid_sync[1:0], s_wvalid_reg};
    end
    wire m_s_wvalid = s_wvalid_sync[2];

    // Synchronizer for s_wready_reg (M -> S)
    reg [2:0] s_wready_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_wready_sync <= 3'b000;
        else
            s_wready_sync <= {s_wready_sync[1:0], s_wready_reg};
    end
    wire s_s_wready = s_wready_sync[2];

    // S-domain: W handshake
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wdata_reg  <= {DATA_WIDTH{1'b0}};
            s_wstrb_reg  <= {STRB_WIDTH{1'b0}};
            s_wvalid_reg <= 1'b0;
            s_wready_reg <= 1'b0;
        end else begin
            if (s_axil_wvalid && s_s_wready) begin
                s_wdata_reg  <= s_axil_wdata;
                s_wstrb_reg  <= s_axil_wstrb;
                s_wvalid_reg <= 1'b1;
            end else if (m_s_wvalid && s_wready_reg) begin
                s_wvalid_reg <= 1'b0;
            end
            if (m_s_wvalid) begin
                s_wready_reg <= 1'b1;
            end else if (s_axil_wvalid && s_s_wready) begin
                s_wready_reg <= 1'b0;
            end
        end
    end

    assign s_axil_wready = s_s_wready;

    // M-domain: W output
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_wdata  <= {DATA_WIDTH{1'b0}};
            m_axil_wstrb  <= {STRB_WIDTH{1'b0}};
            m_axil_wvalid <= 1'b0;
        end else begin
            if (m_s_wvalid) begin
                m_axil_wdata  <= s_wdata_reg;
                m_axil_wstrb  <= s_wstrb_reg;
                m_axil_wvalid <= 1'b1;
            end else if (m_axil_wready) begin
                m_axil_wvalid <= 1'b0;
            end
        end
    end

    // ========================================================================
    // Write Response Channel (B) - Master to Slave
    // ========================================================================
    reg [1:0] s_bresp_reg;
    reg       s_bvalid_reg;
    reg       s_bready_reg;

    // Synchronizer for s_bready_reg (S -> M)
    reg [2:0] s_bready_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            s_bready_sync <= 3'b000;
        else
            s_bready_sync <= {s_bready_sync[1:0], s_bready_reg};
    end
    wire m_s_bready = s_bready_sync[2];

    // Synchronizer for s_bvalid_reg (M -> S)
    reg [2:0] s_bvalid_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_bvalid_sync <= 3'b000;
        else
            s_bvalid_sync <= {s_bvalid_sync[1:0], s_bvalid_reg};
    end
    wire s_s_bvalid = s_bvalid_sync[2];

    // S-domain: B handshake
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_bresp_reg  <= 2'b00;
            s_bvalid_reg <= 1'b0;
            s_bready_reg <= 1'b0;
        end else begin
            if (s_s_bvalid && s_axil_bready) begin
                s_bvalid_reg <= 1'b0;
            end
            if (s_axil_bready) begin
                s_bready_reg <= 1'b1;
            end else if (s_s_bvalid) begin
                s_bready_reg <= 1'b0;
            end
        end
    end

    assign s_axil_bresp  = s_bresp_reg;
    assign s_axil_bvalid = s_s_bvalid;

    // M-domain: B input
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_bready <= 1'b0;
        end else begin
            if (m_axil_bvalid && m_s_bready) begin
                m_axil_bready <= 1'b0;
            end else if (m_s_bready) begin
                m_axil_bready <= 1'b1;
            end
        end
    end

    // S-domain: Capture B response when M-side handshake completes
    // We need to detect when m_axil_bvalid && m_axil_bready happens in M domain,
    // then propagate bresp to S domain.
    // Use a simple pulse synchronizer: M domain generates a pulse when B handshake
    // completes, S domain captures bresp on that pulse.

    // M-domain: detect B handshake completion
    reg m_b_handshake_done;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_b_handshake_done <= 1'b0;
        else
            m_b_handshake_done <= m_axil_bvalid && m_axil_bready;
    end

    // Synchronizer for m_b_handshake_done (M -> S)
    reg [2:0] m_b_handshake_done_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            m_b_handshake_done_sync <= 3'b000;
        else
            m_b_handshake_done_sync <= {m_b_handshake_done_sync[1:0], m_b_handshake_done};
    end
    wire s_m_b_handshake_done = m_b_handshake_done_sync[2];

    // S-domain: capture bresp when handshake done pulse arrives
    // We need to synchronize bresp as well. Since bresp is only valid when
    // bvalid is high, and we're using a pulse to indicate the handshake,
    // we can synchronize bresp using a 2-flop synchronizer and capture it
    // when the pulse is detected.

    reg [1:0] m_bresp_sync1;
    reg [1:0] m_bresp_sync2;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_bresp_sync1 <= 2'b00;
            m_bresp_sync2 <= 2'b00;
        end else begin
            m_bresp_sync1 <= m_axil_bresp;
            m_bresp_sync2 <= m_bresp_sync1;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_bresp_reg  <= 2'b00;
            s_bvalid_reg <= 1'b0;
        end else begin
            if (s_m_b_handshake_done) begin
                s_bresp_reg  <= m_bresp_sync2;
                s_bvalid_reg <= 1'b1;
            end else if (s_s_bvalid && s_axil_bready) begin
                s_bvalid_reg <= 1'b0;
            end
        end
    end

    // ========================================================================
    // Read Address Channel (AR) - Slave to Master
    // ========================================================================
    reg [ADDR_WIDTH-1:0] s_araddr_reg;
    reg [2:0]            s_arprot_reg;
    reg                  s_arvalid_reg;
    reg                  s_arready_reg;

    // Synchronizer for s_arvalid_reg (S -> M)
    reg [2:0] s_arvalid_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            s_arvalid_sync <= 3'b000;
        else
            s_arvalid_sync <= {s_arvalid_sync[1:0], s_arvalid_reg};
    end
    wire m_s_arvalid = s_arvalid_sync[2];

    // Synchronizer for s_arready_reg (M -> S)
    reg [2:0] s_arready_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_arready_sync <= 3'b000;
        else
            s_arready_sync <= {s_arready_sync[1:0], s_arready_reg};
    end
    wire s_s_arready = s_arready_sync[2];

    // S-domain: AR handshake
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_araddr_reg  <= {ADDR_WIDTH{1'b0}};
            s_arprot_reg  <= 3'b000;
            s_arvalid_reg <= 1'b0;
            s_arready_reg <= 1'b0;
        end else begin
            if (s_axil_arvalid && s_s_arready) begin
                s_araddr_reg  <= s_axil_araddr;
                s_arprot_reg  <= s_axil_arprot;
                s_arvalid_reg <= 1'b1;
            end else if (m_s_arvalid && s_arready_reg) begin
                s_arvalid_reg <= 1'b0;
            end
            if (m_s_arvalid) begin
                s_arready_reg <= 1'b1;
            end else if (s_axil_arvalid && s_s_arready) begin
                s_arready_reg <= 1'b0;
            end
        end
    end

    assign s_axil_arready = s_s_arready;

    // M-domain: AR output
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_araddr  <= {ADDR_WIDTH{1'b0}};
            m_axil_arprot  <= 3'b000;
            m_axil_arvalid <= 1'b0;
        end else begin
            if (m_s_arvalid) begin
                m_axil_araddr  <= s_araddr_reg;
                m_axil_arprot  <= s_arprot_reg;
                m_axil_arvalid <= 1'b1;
            end else if (m_axil_arready) begin
                m_axil_arvalid <= 1'b0;
            end
        end
    end

    // ========================================================================
    // Read Data Channel (R) - Master to Slave
    // ========================================================================
    reg [DATA_WIDTH-1:0] s_rdata_reg;
    reg [1:0]            s_rresp_reg;
    reg                  s_rvalid_reg;
    reg                  s_rready_reg;

    // Synchronizer for s_rready_reg (S -> M)
    reg [2:0] s_rready_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            s_rready_sync <= 3'b000;
        else
            s_rready_sync <= {s_rready_sync[1:0], s_rready_reg};
    end
    wire m_s_rready = s_rready_sync[2];

    // Synchronizer for s_rvalid_reg (M -> S)
    reg [2:0] s_rvalid_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_rvalid_sync <= 3'b000;
        else
            s_rvalid_sync <= {s_rvalid_sync[1:0], s_rvalid_reg};
    end
    wire s_s_rvalid = s_rvalid_sync[2];

    // S-domain: R handshake
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_rdata_reg  <= {DATA_WIDTH{1'b0}};
            s_rresp_reg  <= 2'b00;
            s_rvalid_reg <= 1'b0;
            s_rready_reg <= 1'b0;
        end else begin
            if (s_s_rvalid && s_axil_rready) begin
                s_rvalid_reg <= 1'b0;
            end
            if (s_axil_rready) begin
                s_rready_reg <= 1'b1;
            end else if (s_s_rvalid) begin
                s_rready_reg <= 1'b0;
            end
        end
    end

    assign s_axil_rdata  = s_rdata_reg;
    assign s_axil_rresp  = s_rresp_reg;
    assign s_axil_rvalid = s_s_rvalid;

    // M-domain: R input
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_rready <= 1'b0;
        end else begin
            if (m_axil_rvalid && m_s_rready) begin
                m_axil_rready <= 1'b0;
            end else if (m_s_rready) begin
                m_axil_rready <= 1'b1;
            end
        end
    end

    // M-domain: detect R handshake completion
    reg m_r_handshake_done;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_r_handshake_done <= 1'b0;
        else
            m_r_handshake_done <= m_axil_rvalid && m_axil_rready;
    end

    // Synchronizer for m_r_handshake_done (M -> S)
    reg [2:0] m_r_handshake_done_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            m_r_handshake_done_sync <= 3'b000;
        else
            m_r_handshake_done_sync <= {m_r_handshake_done_sync[1:0], m_r_handshake_done};
    end
    wire s_m_r_handshake_done = m_r_handshake_done_sync[2];

    // Synchronize rdata and rresp
    reg [DATA_WIDTH-1:0] m_rdata_sync1;
    reg [DATA_WIDTH-1:0] m_rdata_sync2;
    reg [1:0]            m_rresp_sync1;
    reg [1:0]            m_rresp_sync2;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_rdata_sync1 <= {DATA_WIDTH{1'b0}};
            m_rdata_sync2 <= {DATA_WIDTH{1'b0}};
            m_rresp_sync1 <= 2'b00;
            m_rresp_sync2 <= 2'b00;
        end else begin
            m_rdata_sync1 <= m_axil_rdata;
            m_rdata_sync2 <= m_rdata_sync1;
            m_rresp_sync1 <= m_axil_rresp;
            m_rresp_sync2 <= m_rresp_sync1;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_rdata_reg  <= {DATA_WIDTH{1'b0}};
            s_rresp_reg  <= 2'b00;
            s_rvalid_reg <= 1'b0;
        end else begin
            if (s_m_r_handshake_done) begin
                s_rdata_reg  <= m_rdata_sync2;
                s_rresp_reg  <= m_rresp_sync2;
                s_rvalid_reg <= 1'b1;
            end else if (s_s_rvalid && s_axil_rready) begin
                s_rvalid_reg <= 1'b0;
            end
        end
    end

endmodule
