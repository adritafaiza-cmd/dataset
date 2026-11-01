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
    // Synchronous reset synchronizers
    // ========================================================================
    reg [1:0] s_rst_sync;
    reg [1:0] m_rst_sync;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_rst_sync <= 2'b11;
        else
            s_rst_sync <= {s_rst_sync[0], 1'b0};
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_rst_sync <= 2'b11;
        else
            m_rst_sync <= {m_rst_sync[0], 1'b0};
    end

    wire s_rst_synced = s_rst_sync[1];
    wire m_rst_synced = m_rst_sync[1];

    // ========================================================================
    // Write Address Channel: S -> M
    // ========================================================================
    // S-domain: capture AW when valid and ready
    reg        s_aw_pending;
    reg [ADDR_WIDTH-1:0] s_aw_addr;
    reg [2:0]  s_aw_prot;

    // M-domain: handshake
    reg        m_aw_req;
    reg [ADDR_WIDTH-1:0] m_aw_addr;
    reg [2:0]  m_aw_prot;
    reg        m_aw_ack;
    reg [1:0]  m_aw_ack_sync;

    // S-domain: acknowledge from M
    reg [1:0]  s_aw_ack_sync;
    wire       s_aw_ack = s_aw_ack_sync[1];

    // S-domain: AW ready
    assign s_axil_awready = !s_aw_pending && !s_rst_synced;

    // S-domain: capture AW
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_aw_pending <= 1'b0;
            s_aw_addr    <= {ADDR_WIDTH{1'b0}};
            s_aw_prot    <= 3'b000;
            s_aw_ack_sync <= 2'b00;
        end else begin
            if (s_axil_awvalid && s_axil_awready) begin
                s_aw_pending <= 1'b1;
                s_aw_addr    <= s_axil_awaddr;
                s_aw_prot    <= s_axil_awprot;
            end
            if (s_aw_ack && s_aw_pending) begin
                s_aw_pending <= 1'b0;
            end
            s_aw_ack_sync <= {s_aw_ack_sync[0], m_aw_ack};
        end
    end

    // M-domain: AW handshake
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_aw_req  <= 1'b0;
            m_aw_addr <= {ADDR_WIDTH{1'b0}};
            m_aw_prot <= 3'b000;
            m_aw_ack  <= 1'b0;
            m_aw_ack_sync <= 2'b00;
        end else begin
            // Request from S
            if (s_aw_pending && !m_aw_req) begin
                m_aw_req  <= 1'b1;
                m_aw_addr <= s_aw_addr;
                m_aw_prot <= s_aw_prot;
            end
            // Acknowledge to S
            if (m_aw_req && m_axil_awready) begin
                m_aw_ack <= 1'b1;
            end
            if (m_aw_ack && !s_aw_pending) begin
                m_aw_ack <= 1'b0;
            end
            m_aw_ack_sync <= {m_aw_ack_sync[0], s_aw_ack};
        end
    end

    // M-domain: AW outputs
    assign m_axil_awaddr  = m_aw_addr;
    assign m_axil_awprot  = m_aw_prot;
    assign m_axil_awvalid = m_aw_req;

    // ========================================================================
    // Write Data Channel: S -> M
    // ========================================================================
    // S-domain: capture W when valid and ready
    reg        s_w_pending;
    reg [DATA_WIDTH-1:0] s_w_data;
    reg [STRB_WIDTH-1:0] s_w_strb;

    // M-domain: handshake
    reg        m_w_req;
    reg [DATA_WIDTH-1:0] m_w_data;
    reg [STRB_WIDTH-1:0] m_w_strb;
    reg        m_w_ack;
    reg [1:0]  m_w_ack_sync;

    // S-domain: acknowledge from M
    reg [1:0]  s_w_ack_sync;
    wire       s_w_ack = s_w_ack_sync[1];

    // S-domain: W ready
    assign s_axil_wready = !s_w_pending && !s_rst_synced;

    // S-domain: capture W
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_w_pending <= 1'b0;
            s_w_data    <= {DATA_WIDTH{1'b0}};
            s_w_strb    <= {STRB_WIDTH{1'b0}};
            s_w_ack_sync <= 2'b00;
        end else begin
            if (s_axil_wvalid && s_axil_wready) begin
                s_w_pending <= 1'b1;
                s_w_data    <= s_axil_wdata;
                s_w_strb    <= s_axil_wstrb;
            end
            if (s_w_ack && s_w_pending) begin
                s_w_pending <= 1'b0;
            end
            s_w_ack_sync <= {s_w_ack_sync[0], m_w_ack};
        end
    end

    // M-domain: W handshake
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_w_req  <= 1'b0;
            m_w_data <= {DATA_WIDTH{1'b0}};
            m_w_strb <= {STRB_WIDTH{1'b0}};
            m_w_ack  <= 1'b0;
            m_w_ack_sync <= 2'b00;
        end else begin
            // Request from S
            if (s_w_pending && !m_w_req) begin
                m_w_req  <= 1'b1;
                m_w_data <= s_w_data;
                m_w_strb <= s_w_strb;
            end
            // Acknowledge to S
            if (m_w_req && m_axil_wready) begin
                m_w_ack <= 1'b1;
            end
            if (m_w_ack && !s_w_pending) begin
                m_w_ack <= 1'b0;
            end
            m_w_ack_sync <= {m_w_ack_sync[0], s_w_ack};
        end
    end

    // M-domain: W outputs
    assign m_axil_wdata  = m_w_data;
    assign m_axil_wstrb  = m_w_strb;
    assign m_axil_wvalid = m_w_req;

    // ========================================================================
    // Write Response Channel: M -> S
    // ========================================================================
    // M-domain: capture B when valid and ready
    reg        m_b_pending;
    reg [1:0]  m_b_resp;

    // S-domain: handshake
    reg        s_b_req;
    reg [1:0]  s_b_resp;
    reg        s_b_ack;
    reg [1:0]  s_b_ack_sync;

    // M-domain: acknowledge from S
    reg [1:0]  m_b_ack_sync;
    wire       m_b_ack = m_b_ack_sync[1];

    // M-domain: B ready
    assign m_axil_bready = !m_b_pending && !m_rst_synced;

    // M-domain: capture B
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_b_pending <= 1'b0;
            m_b_resp    <= 2'b00;
            m_b_ack_sync <= 2'b00;
        end else begin
            if (m_axil_bvalid && m_axil_bready) begin
                m_b_pending <= 1'b1;
                m_b_resp    <= m_axil_bresp;
            end
            if (m_b_ack && m_b_pending) begin
                m_b_pending <= 1'b0;
            end
            m_b_ack_sync <= {m_b_ack_sync[0], s_b_ack};
        end
    end

    // S-domain: B handshake
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_b_req  <= 1'b0;
            s_b_resp <= 2'b00;
            s_b_ack  <= 1'b0;
            s_b_ack_sync <= 2'b00;
        end else begin
            // Request from M
            if (m_b_pending && !s_b_req) begin
                s_b_req  <= 1'b1;
                s_b_resp <= m_b_resp;
            end
            // Acknowledge to M
            if (s_b_req && s_axil_bready) begin
                s_b_ack <= 1'b1;
            end
            if (s_b_ack && !m_b_pending) begin
                s_b_ack <= 1'b0;
            end
            s_b_ack_sync <= {s_b_ack_sync[0], m_b_ack};
        end
    end

    // S-domain: B outputs
    assign s_axil_bresp  = s_b_resp;
    assign s_axil_bvalid = s_b_req;

    // ========================================================================
    // Read Address Channel: S -> M
    // ========================================================================
    // S-domain: capture AR when valid and ready
    reg        s_ar_pending;
    reg [ADDR_WIDTH-1:0] s_ar_addr;
    reg [2:0]  s_ar_prot;

    // M-domain: handshake
    reg        m_ar_req;
    reg [ADDR_WIDTH-1:0] m_ar_addr;
    reg [2:0]  m_ar_prot;
    reg        m_ar_ack;
    reg [1:0]  m_ar_ack_sync;

    // S-domain: acknowledge from M
    reg [1:0]  s_ar_ack_sync;
    wire       s_ar_ack = s_ar_ack_sync[1];

    // S-domain: AR ready
    assign s_axil_arready = !s_ar_pending && !s_rst_synced;

    // S-domain: capture AR
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_ar_pending <= 1'b0;
            s_ar_addr    <= {ADDR_WIDTH{1'b0}};
            s_ar_prot    <= 3'b000;
            s_ar_ack_sync <= 2'b00;
        end else begin
            if (s_axil_arvalid && s_axil_arready) begin
                s_ar_pending <= 1'b1;
                s_ar_addr    <= s_axil_araddr;
                s_ar_prot    <= s_axil_arprot;
            end
            if (s_ar_ack && s_ar_pending) begin
                s_ar_pending <= 1'b0;
            end
            s_ar_ack_sync <= {s_ar_ack_sync[0], m_ar_ack};
        end
    end

    // M-domain: AR handshake
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_ar_req  <= 1'b0;
            m_ar_addr <= {ADDR_WIDTH{1'b0}};
            m_ar_prot <= 3'b000;
            m_ar_ack  <= 1'b0;
            m_ar_ack_sync <= 2'b00;
        end else begin
            // Request from S
            if (s_ar_pending && !m_ar_req) begin
                m_ar_req  <= 1'b1;
                m_ar_addr <= s_ar_addr;
                m_ar_prot <= s_ar_prot;
            end
            // Acknowledge to S
            if (m_ar_req && m_axil_arready) begin
                m_ar_ack <= 1'b1;
            end
            if (m_ar_ack && !s_ar_pending) begin
                m_ar_ack <= 1'b0;
            end
            m_ar_ack_sync <= {m_ar_ack_sync[0], s_ar_ack};
        end
    end

    // M-domain: AR outputs
    assign m_axil_araddr  = m_ar_addr;
    assign m_axil_arprot  = m_ar_prot;
    assign m_axil_arvalid = m_ar_req;

    // ========================================================================
    // Read Data Channel: M -> S
    // ========================================================================
    // M-domain: capture R when valid and ready
    reg        m_r_pending;
    reg [DATA_WIDTH-1:0] m_r_data;
    reg [1:0]  m_r_resp;

    // S-domain: handshake
    reg        s_r_req;
    reg [DATA_WIDTH-1:0] s_r_data;
    reg [1:0]  s_r_resp;
    reg        s_r_ack;
    reg [1:0]  s_r_ack_sync;

    // M-domain: acknowledge from S
    reg [1:0]  m_r_ack_sync;
    wire       m_r_ack = m_r_ack_sync[1];

    // M-domain: R ready
    assign m_axil_rready = !m_r_pending && !m_rst_synced;

    // M-domain: capture R
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_r_pending <= 1'b0;
            m_r_data    <= {DATA_WIDTH{1'b0}};
            m_r_resp    <= 2'b00;
            m_r_ack_sync <= 2'b00;
        end else begin
            if (m_axil_rvalid && m_axil_rready) begin
                m_r_pending <= 1'b1;
                m_r_data    <= m_axil_rdata;
                m_r_resp    <= m_axil_rresp;
            end
            if (m_r_ack && m_r_pending) begin
                m_r_pending <= 1'b0;
            end
            m_r_ack_sync <= {m_r_ack_sync[0], s_r_ack};
        end
    end

    // S-domain: R handshake
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_r_req  <= 1'b0;
            s_r_data <= {DATA_WIDTH{1'b0}};
            s_r_resp <= 2'b00;
            s_r_ack  <= 1'b0;
            s_r_ack_sync <= 2'b00;
        end else begin
            // Request from M
            if (m_r_pending && !s_r_req) begin
                s_r_req  <= 1'b1;
                s_r_data <= m_r_data;
                s_r_resp <= m_r_resp;
            end
            // Acknowledge to M
            if (s_r_req && s_axil_rready) begin
                s_r_ack <= 1'b1;
            end
            if (s_r_ack && !m_r_pending) begin
                s_r_ack <= 1'b0;
            end
            s_r_ack_sync <= {s_r_ack_sync[0], m_r_ack};
        end
    end

    // S-domain: R outputs
    assign s_axil_rdata  = s_r_data;
    assign s_axil_rresp  = s_r_resp;
    assign s_axil_rvalid = s_r_req;

endmodule
