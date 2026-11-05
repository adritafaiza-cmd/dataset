// =============================================================================
// AXI4-Lite Clock Domain Crossing (CDC) Bridge
// =============================================================================
//
// This module bridges AXI4-Lite transactions between two asynchronous clock
// domains. It uses a request/acknowledge handshake protocol with 2-stage
// synchronizers for safe CDC.
//
// Architecture:
//   - Write path: AW and W channels are combined into a single write request
//   - Read path: AR channel is forwarded as a read request
//   - Response path: B and R responses are forwarded back to the slave side
//
// CDC Protocol:
//   1. Source side: Hold payload stable, assert request
//   2. Destination side: Synchronize request (2-stage), capture payload
//   3. Destination side: Process transaction, assert acknowledge
//   4. Source side: Synchronize acknowledge (2-stage), release payload
//
// =============================================================================

module axil_cdc #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = (DATA_WIDTH/8)
) (
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

    // =========================================================================
    // Write Channel (AW + W) - Slave to Master
    // =========================================================================

    // Slave side: Wait for both AW and W to be valid
    wire s_write_valid = s_axil_awvalid && s_axil_wvalid;

    // Hold write payload stable while request is pending
    reg [ADDR_WIDTH-1:0] s_waddr_hold;
    reg [2:0]            s_wprot_hold;
    reg [DATA_WIDTH-1:0] s_wdata_hold;
    reg [STRB_WIDTH-1:0] s_wstrb_hold;
    reg                  s_write_pending;

    // Request/acknowledge handshake signals
    reg                  s_write_req;
    wire                 s_write_ack;

    // Capture write payload when both channels are valid
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_waddr_hold    <= {ADDR_WIDTH{1'b0}};
            s_wprot_hold    <= 3'b000;
            s_wdata_hold    <= {DATA_WIDTH{1'b0}};
            s_wstrb_hold    <= {STRB_WIDTH{1'b0}};
            s_write_pending <= 1'b0;
            s_write_req     <= 1'b0;
        end else begin
            if (!s_write_pending && s_write_valid) begin
                // Capture payload and initiate request
                s_waddr_hold    <= s_axil_awaddr;
                s_wprot_hold    <= s_axil_awprot;
                s_wdata_hold    <= s_axil_wdata;
                s_wstrb_hold    <= s_axil_wstrb;
                s_write_pending <= 1'b1;
                s_write_req     <= 1'b1;
            end else if (s_write_pending && s_write_ack) begin
                // Acknowledge received, release pending
                s_write_pending <= 1'b0;
                s_write_req     <= 1'b0;
            end
        end
    end

    // Slave side ready signals
    assign s_axil_awready = !s_write_pending;
    assign s_axil_wready  = !s_write_pending;

    // Master side: Synchronize request and capture payload
    reg [2:0] m_write_req_sync;
    reg       m_write_req_valid;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_write_req_sync    <= 3'b000;
            m_write_req_valid   <= 1'b0;
        end else begin
            m_write_req_sync <= {m_write_req_sync[1:0], s_write_req};

            if (!m_write_req_valid && m_write_req_sync[1]) begin
                // Request synchronized, capture payload and assert valid
                m_write_req_valid <= 1'b1;
            end else if (m_write_req_valid && m_write_ack) begin
                // Acknowledge received, clear valid
                m_write_req_valid <= 1'b0;
            end
        end
    end

    // Master side AXI signals
    assign m_axil_awaddr  = s_waddr_hold;
    assign m_axil_awprot  = s_wprot_hold;
    assign m_axil_awvalid = m_write_req_valid;

    assign m_axil_wdata   = s_wdata_hold;
    assign m_axil_wstrb   = s_wstrb_hold;
    assign m_axil_wvalid  = m_write_req_valid;

    // Wait for both AW and W to be accepted
    wire m_write_done = m_axil_awready && m_axil_wready;

    // Master side acknowledge
    reg m_write_ack;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_write_ack <= 1'b0;
        end else if (m_write_req_valid && m_write_done) begin
            m_write_ack <= 1'b1;
        end else if (!m_write_req_valid) begin
            m_write_ack <= 1'b0;
        end
    end

    // Synchronize acknowledge back to slave side
    reg [2:0] s_write_ack_sync;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_write_ack_sync <= 3'b000;
        end else begin
            s_write_ack_sync <= {s_write_ack_sync[1:0], m_write_ack};
        end
    end

    assign s_write_ack = s_write_ack_sync[1];

    // =========================================================================
    // Write Response (B) - Master to Slave
    // =========================================================================

    // Master side: Forward B response
    assign m_axil_bready = 1'b1;

    // Slave side: Synchronize B response
    reg [1:0] s_bresp_sync;
    reg       s_bvalid_sync;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_bresp_sync  <= 2'b00;
            s_bvalid_sync <= 1'b0;
        end else begin
            s_bresp_sync  <= {s_bresp_sync[0], m_axil_bresp[0]};
            s_bvalid_sync <= m_axil_bvalid;
        end
    end

    assign s_axil_bresp  = s_bresp_sync;
    assign s_axil_bvalid = s_bvalid_sync;

    // =========================================================================
    // Read Address Channel (AR) - Slave to Master
    // =========================================================================

    // Slave side: Hold read address stable while request is pending
    reg [ADDR_WIDTH-1:0] s_raddr_hold;
    reg [2:0]            s_rprot_hold;
    reg                  s_read_pending;

    // Request/acknowledge handshake signals
    reg                  s_read_req;
    wire                 s_read_ack;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_raddr_hold   <= {ADDR_WIDTH{1'b0}};
            s_rprot_hold   <= 3'b000;
            s_read_pending <= 1'b0;
            s_read_req     <= 1'b0;
        end else begin
            if (!s_read_pending && s_axil_arvalid) begin
                // Capture address and initiate request
                s_raddr_hold   <= s_axil_araddr;
                s_rprot_hold   <= s_axil_arprot;
                s_read_pending <= 1'b1;
                s_read_req     <= 1'b1;
            end else if (s_read_pending && s_read_ack) begin
                // Acknowledge received, release pending
                s_read_pending <= 1'b0;
                s_read_req     <= 1'b0;
            end
        end
    end

    // Slave side ready signal
    assign s_axil_arready = !s_read_pending;

    // Master side: Synchronize request and capture payload
    reg [2:0] m_read_req_sync;
    reg       m_read_req_valid;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_read_req_sync <= 3'b000;
            m_read_req_valid <= 1'b0;
        end else begin
            m_read_req_sync <= {m_read_req_sync[1:0], s_read_req};

            if (!m_read_req_valid && m_read_req_sync[1]) begin
                // Request synchronized, assert valid
                m_read_req_valid <= 1'b1;
            end else if (m_read_req_valid && m_read_ack) begin
                // Acknowledge received, clear valid
                m_read_req_valid <= 1'b0;
            end
        end
    end

    // Master side AXI signals
    assign m_axil_araddr  = s_raddr_hold;
    assign m_axil_arprot  = s_rprot_hold;
    assign m_axil_arvalid = m_read_req_valid;

    // Master side acknowledge
    reg m_read_ack;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_read_ack <= 1'b0;
        end else if (m_read_req_valid && m_axil_arready) begin
            m_read_ack <= 1'b1;
        end else if (!m_read_req_valid) begin
            m_read_ack <= 1'b0;
        end
    end

    // Synchronize acknowledge back to slave side
    reg [2:0] s_read_ack_sync;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_read_ack_sync <= 3'b000;
        end else begin
            s_read_ack_sync <= {s_read_ack_sync[1:0], m_read_ack};
        end
    end

    assign s_read_ack = s_read_ack_sync[1];

    // =========================================================================
    // Read Data Channel (R) - Master to Slave
    // =========================================================================

    // Master side: Forward R response
    assign m_axil_rready = 1'b1;

    // Slave side: Synchronize R response
    reg [DATA_WIDTH-1:0] s_rdata_sync;
    reg [1:0]            s_rresp_sync;
    reg                  s_rvalid_sync;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_rdata_sync  <= {DATA_WIDTH{1'b0}};
            s_rresp_sync  <= 2'b00;
            s_rvalid_sync <= 1'b0;
        end else begin
            s_rdata_sync  <= m_axil_rdata;
            s_rresp_sync  <= {s_rresp_sync[0], m_axil_rresp[0]};
            s_rvalid_sync <= m_axil_rvalid;
        end
    end

    assign s_axil_rdata  = s_rdata_sync;
    assign s_axil_rresp  = s_rresp_sync;
    assign s_axil_rvalid = s_rvalid_sync;

endmodule