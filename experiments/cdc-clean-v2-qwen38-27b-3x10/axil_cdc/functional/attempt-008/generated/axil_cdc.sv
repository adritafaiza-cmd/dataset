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
    // Slave side: capture AW when valid and ready
    reg        s_aw_valid;
    reg [ADDR_WIDTH-1:0] s_aw_addr;
    reg [2:0]  s_aw_prot;
    reg        s_aw_sent;  // indicates AW has been sent to master side

    wire s_aw_ready = !s_aw_valid || s_aw_sent;
    assign s_axil_awready = s_aw_ready;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_aw_valid <= 1'b0;
            s_aw_addr  <= {ADDR_WIDTH{1'b0}};
            s_aw_prot  <= 3'b000;
            s_aw_sent  <= 1'b0;
        end else begin
            if (s_axil_awvalid && s_aw_ready) begin
                s_aw_valid <= 1'b1;
                s_aw_addr  <= s_axil_awaddr;
                s_aw_prot  <= s_axil_awprot;
                s_aw_sent  <= 1'b0;
            end else if (s_aw_valid && s_aw_sent) begin
                s_aw_valid <= 1'b0;
                s_aw_sent  <= 1'b0;
            end
        end
    end

    // Master side: receive AW
    reg        m_aw_valid;
    reg [ADDR_WIDTH-1:0] m_aw_addr;
    reg [2:0]  m_aw_prot;
    reg        m_aw_ack;  // master side acknowledges receipt

    // Handshake: slave sends when s_aw_valid && !s_aw_sent
    // Master receives when m_aw_valid && !m_aw_ack
    // We use a simple toggle-based handshake

    // Slave side: pulse to master when AW is ready to send
    reg s_aw_pulse;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_aw_pulse <= 1'b0;
        else
            s_aw_pulse <= s_aw_valid && !s_aw_sent;
    end

    // Master side: detect pulse and capture
    reg m_aw_pulse_sync1, m_aw_pulse_sync2;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_aw_pulse_sync1 <= 1'b0;
            m_aw_pulse_sync2 <= 1'b0;
        end else begin
            m_aw_pulse_sync1 <= s_aw_pulse;
            m_aw_pulse_sync2 <= m_aw_pulse_sync1;
        end
    end

    wire m_aw_pulse_edge = m_aw_pulse_sync2 && !m_aw_pulse_sync1;

    // But we need to ensure data is stable. Let's use a different approach:
    // Use a valid/ready handshake across CDC with proper synchronization.

    // Actually, let's use a simpler and more robust approach:
    // For each channel, use a 2-phase handshake with level signals.

    // Let me redesign with a cleaner approach using explicit state machines.

    // ========================================================================
    // AW Channel CDC
    // ========================================================================
    // Slave side state
    reg s_aw_state;
    localparam S_AW_IDLE = 1'b0;
    localparam S_AW_WAIT = 1'b1;

    // Master side state
    reg m_aw_state;
    localparam M_AW_IDLE = 1'b0;
    localparam M_AW_WAIT = 1'b1;

    // Slave sends AW: assert s_aw_go when in WAIT state
    wire s_aw_go = (s_aw_state == S_AW_WAIT);

    // Master receives AW: when m_aw_state == M_AW_WAIT and s_aw_go is synchronized
    reg m_s_aw_go_sync1, m_s_aw_go_sync2;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_s_aw_go_sync1 <= 1'b0;
            m_s_aw_go_sync2 <= 1'b0;
        end else begin
            m_s_aw_go_sync1 <= s_aw_go;
            m_s_aw_go_sync2 <= m_s_aw_go_sync1;
        end
    end

    // Master captures AW data when it sees the go signal
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_aw_state  <= M_AW_IDLE;
            m_aw_addr   <= {ADDR_WIDTH{1'b0}};
            m_aw_prot   <= 3'b000;
            m_aw_valid  <= 1'b0;
        end else begin
            if (m_aw_state == M_AW_IDLE) begin
                if (m_s_aw_go_sync2) begin
                    m_aw_state <= M_AW_WAIT;
                    m_aw_addr  <= s_aw_addr;
                    m_aw_prot  <= s_aw_prot;
                    m_aw_valid <= 1'b1;
                end
            end else if (m_aw_state == M_AW_WAIT) begin
                // Wait for slave to acknowledge
                // Slave will deassert s_aw_go after seeing m_aw_ack
            end
        end
    end

    // Master acknowledges: assert m_aw_ack
    reg m_aw_ack;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_aw_ack <= 1'b0;
        else
            m_aw_ack <= (m_aw_state == M_AW_WAIT);
    end

    // Slave side: synchronize m_aw_ack
    reg s_m_aw_ack_sync1, s_m_aw_ack_sync2;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_m_aw_ack_sync1 <= 1'b0;
            s_m_aw_ack_sync2 <= 1'b0;
        end else begin
            s_m_aw_ack_sync1 <= m_aw_ack;
            s_m_aw_ack_sync2 <= s_m_aw_ack_sync1;
        end
    end

    // Slave state machine
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_aw_state <= S_AW_IDLE;
            s_aw_valid <= 1'b0;
            s_aw_addr  <= {ADDR_WIDTH{1'b0}};
            s_aw_prot  <= 3'b000;
            s_aw_sent  <= 1'b0;
        end else begin
            if (s_aw_state == S_AW_IDLE) begin
                if (s_axil_awvalid) begin
                    s_aw_state <= S_AW_WAIT;
                    s_aw_valid <= 1'b1;
                    s_aw_addr  <= s_axil_awaddr;
                    s_aw_prot  <= s_axil_awprot;
                    s_aw_sent  <= 1'b0;
                end
            end else if (s_aw_state == S_AW_WAIT) begin
                if (s_m_aw_ack_sync2) begin
                    s_aw_state <= S_AW_IDLE;
                    s_aw_valid <= 1'b0;
                    s_aw_sent  <= 1'b1;
                end
            end
        end
    end

    // Master AW output
    assign m_axil_awaddr  = m_aw_addr;
    assign m_axil_awprot  = m_aw_prot;
    assign m_axil_awvalid = m_aw_valid;

    // Master AW ready: when master is idle or waiting for next
    // We can accept a new AW when m_aw_state is IDLE
    // But we need to handle the case where m_aw_valid is asserted and m_axil_awready
    // Let's simplify: m_aw_valid is asserted when we have a pending AW
    // m_axil_awready is input from the master side device

    // Actually, let's reconsider the design. The master side should present
    // m_axil_awvalid when it has an AW to send, and wait for m_axil_awready.
    // The slave side should present s_axil_awready when it can accept a new AW.

    // Let me restart with a cleaner architecture.

endmodule
