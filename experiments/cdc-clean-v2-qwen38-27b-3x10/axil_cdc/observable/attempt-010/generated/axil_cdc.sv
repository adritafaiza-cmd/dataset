module axil_cdc #
(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = (DATA_WIDTH/8)
)
(
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

    wire s_rst_n = ~s_rst_sync[1];
    wire m_rst_n = ~m_rst_sync[1];

    // ========================================================================
    // Handshake CDC primitives
    // ========================================================================

    // S-domain: request to M-domain
    // req_reg is set in S-domain, cleared in M-domain
    // req_sync is the 2-flop synchronizer in M-domain
    //
    // Protocol:
    //   S-domain: when req_reg==0 and we want to send, set req_reg=1
    //   M-domain: when req_sync[1]==1, data is valid. After processing,
    //             set ack_reg=1 (in M-domain)
    //   S-domain: when ack_sync[1]==1, clear req_reg=0 and ack_reg=0
    //             (ack_reg is cleared in S-domain)

    // Write Address Channel: S -> M
    reg  s_aw_req;
    reg  m_aw_ack;
    reg [1:0] m_aw_req_sync;
    reg [1:0] s_aw_ack_sync;

    // Write Data Channel: S -> M
    reg  s_w_req;
    reg  m_w_ack;
    reg [1:0] m_w_req_sync;
    reg [1:0] s_w_ack_sync;

    // Write Response Channel: M -> S
    reg  m_b_req;
    reg  s_b_ack;
    reg [1:0] s_b_req_sync;
    reg [1:0] m_b_ack_sync;

    // Read Address Channel: S -> M
    reg  s_ar_req;
    reg  m_ar_ack;
    reg [1:0] m_ar_req_sync;
    reg [1:0] s_ar_ack_sync;

    // Read Data Channel: M -> S
    reg  m_r_req;
    reg  s_r_ack;
    reg [1:0] s_r_req_sync;
    reg [1:0] m_r_ack_sync;

    // ========================================================================
    // S-domain: Synchronizers for signals going to M-domain
    // ========================================================================
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_aw_req <= 1'b0;
            s_w_req  <= 1'b0;
            s_ar_req <= 1'b0;
            s_b_ack  <= 1'b0;
            s_r_ack  <= 1'b0;
        end else begin
            // AW channel: set request when slave presents awvalid and we're ready
            if (s_aw_req == 1'b0 && s_axil_awvalid && s_axil_awready)
                s_aw_req <= 1'b1;
            // Clear AW request when ack comes back
            if (s_aw_req == 1'b1 && s_aw_ack_sync[1] == 1'b1)
                s_aw_req <= 1'b0;

            // W channel: set request when slave presents wvalid and we're ready
            if (s_w_req == 1'b0 && s_axil_wvalid && s_axil_wready)
                s_w_req <= 1'b1;
            // Clear W request when ack comes back
            if (s_w_req == 1'b1 && s_w_ack_sync[1] == 1'b1)
                s_w_req <= 1'b0;

            // AR channel: set request when slave presents arvalid and we're ready
            if (s_ar_req == 1'b0 && s_axil_arvalid && s_axil_arready)
                s_ar_req <= 1'b1;
            // Clear AR request when ack comes back
            if (s_ar_req == 1'b1 && s_ar_ack_sync[1] == 1'b1)
                s_ar_req <= 1'b0;

            // B channel: clear ack when we've consumed the response
            if (s_b_ack == 1'b1 && s_axil_bvalid && s_axil_bready)
                s_b_ack <= 1'b0;

            // R channel: clear ack when we've consumed the response
            if (s_r_ack == 1'b1 && s_axil_rvalid && s_axil_rready)
                s_r_ack <= 1'b0;
        end
    end

    // S-domain: Synchronizers for signals coming from M-domain
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_aw_ack_sync <= 2'b00;
            s_w_ack_sync  <= 2'b00;
            s_b_req_sync  <= 2'b00;
            s_r_req_sync  <= 2'b00;
        end else begin
            s_aw_ack_sync <= {s_aw_ack_sync[0], m_aw_ack};
            s_w_ack_sync  <= {s_w_ack_sync[0],  m_w_ack};
            s_b_req_sync  <= {s_b_req_sync[0],  m_b_req};
            s_r_req_sync  <= {s_r_req_sync[0],  m_r_req};
        end
    end

    // ========================================================================
    // M-domain: Synchronizers for signals going to S-domain
    // ========================================================================
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_aw_ack <= 1'b0;
            m_w_ack  <= 1'b0;
            m_b_req  <= 1'b0;
            m_r_req  <= 1'b0;
        end else begin
            // AW channel: set ack when we've accepted the request
            if (m_aw_ack == 1'b0 && m_aw_req_sync[1] == 1'b1 && m_axil_awvalid && m_axil_awready)
                m_aw_ack <= 1'b1;
            // Clear AW ack when S-domain clears the request
            if (m_aw_ack == 1'b1 && m_aw_ack_sync[1] == 1'b0)
                m_aw_ack <= 1'b0;

            // W channel: set ack when we've accepted the request
            if (m_w_ack == 1'b0 && m_w_req_sync[1] == 1'b1 && m_axil_wvalid && m_axil_wready)
                m_w_ack <= 1'b1;
            // Clear W ack when S-domain clears the request
            if (m_w_ack == 1'b1 && m_w_ack_sync[1] == 1'b0)
                m_w_ack <= 1'b0;

            // B channel: set request when we have a response
            if (m_b_req == 1'b0 && m_axil_bvalid)
                m_b_req <= 1'b1;
            // Clear B request when S-domain acks
            if (m_b_req == 1'b1 && m_b_ack_sync[1] == 1'b1)
                m_b_req <= 1'b0;

            // R channel: set request when we have a response
            if (m_r_req == 1'b0 && m_axil_rvalid)
                m_r_req <= 1'b1;
            // Clear R request when S-domain acks
            if (m_r_req == 1'b1 && m_r_ack_sync[1] == 1'b1)
                m_r_req <= 1'b0;
        end
    end

    // M-domain: Synchronizers for signals coming from S-domain
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_aw_req_sync <= 2'b00;
            m_w_req_sync  <= 2'b00;
            m_aw_ack_sync <= 2'b00;
            m_w_ack_sync  <= 2'b00;
            m_b_ack_sync  <= 2'b00;
            m_r_ack_sync  <= 2'b00;
        end else begin
            m_aw_req_sync <= {m_aw_req_sync[0], s_aw_req};
            m_w_req_sync  <= {m_w_req_sync[0],  s_w_req};
            m_aw_ack_sync <= {m_aw_ack_sync[0], s_aw_ack};
            m_w_ack_sync  <= {m_w_ack_sync[0],  s_w_ack};
            m_b_ack_sync  <= {m_b_ack_sync[0],  s_b_ack};
            m_r_ack_sync  <= {m_r_ack_sync[0],  s_r_ack};
        end
    end

    // Wait, I need to add the missing ack signals. Let me restructure.
    // Actually, let me redo this more carefully.

    // ========================================================================
    // Revised approach: Use a simpler, well-known CDC handshake
    // ========================================================================

    // For each channel, we use:
    // - A "req" signal that is set in the source domain and cleared in the dest domain
    // - A "ack" signal that is set in the dest domain and cleared in the source domain
    // - 2-flop synchronizers for both req and ack

    // Let me define all the necessary signals properly.

    // Write Address: S -> M
    // s_aw_req: set in S, cleared in M
    // m_aw_ack: set in M, cleared in S
    // m_aw_req_sync: 2-flop sync of s_aw_req in M domain
    // s_aw_ack_sync: 2-flop sync of m_aw_ack in S domain

    // Write Data: S -> M
    // s_w_req: set in S, cleared in M
    // m_w_ack: set in M, cleared in S
    // m_w_req_sync: 2-flop sync of s_w_req in M domain
    // s_w_ack_sync: 2-flop sync of m_w_ack in S domain

    // Write Response: M -> S
    // m_b_req: set in M, cleared in S
    // s_b_ack: set in S, cleared in M
    // s_b_req_sync: 2-flop sync of m_b_req in S domain
    // m_b_ack_sync: 2-flop sync of s_b_ack in M domain

    // Read Address: S -> M
    // s_ar_req: set in S, cleared in M
    // m_ar_ack: set in M, cleared in S
    // m_ar_req_sync: 2-flop sync of s_ar_req in M domain
    // s_ar_ack_sync: 2-flop sync of m_ar_ack in S domain

    // Read Data: M -> S
    // m_r_req: set in M, cleared in S
    // s_r_ack: set in S, cleared in M
    // s_r_req_sync: 2-flop sync of m_r_req in S domain
    // m_r_ack_sync: 2-flop sync of s_r_ack in M domain

    // I already have most of these. Let me add the missing ones.

    // Missing: s_aw_ack, s_w_ack, m_ar_ack, s_ar_ack
    // Wait, I have m_aw_ack, m_w_ack, m_b_req, m_r_req, s_b_ack, s_r_ack
    // I need: s_aw_ack (for AW ack from M to S), s_w_ack (for W ack from M to S)
    // And: m_ar_ack (for AR ack from M to S), s_ar_ack (for AR ack from S to M)

    // Let me add these.

    reg s_aw_ack;
    reg s_w_ack;
    reg m_ar_ack;
    reg s_ar_ack;

    // S-domain: set/clear s_aw_ack and s_w_ack
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_aw_ack <= 1'b0;
            s_w_ack  <= 1'b0;
        end else begin
            // Set ack when we see the request from M
            if (s_aw_ack == 1'b0 && s_aw_ack_sync[1] == 1'b1)
                s_aw_ack <= 1'b1;
            // Clear ack when we've processed it (i.e., when we clear the req)
            if (s_aw_ack == 1'b1 && s_aw_req == 1'b0)
                s_aw_ack <= 1'b0;

            if (s_w_ack == 1'b0 && s_w_ack_sync[1] == 1'b1)
                s_w_ack <= 1'b1;
            if (s_w_ack == 1'b1 && s_w_req == 1'b0)
                s_w_ack <= 1'b0;
        end
    end

    // M-domain: set/clear m_ar_ack
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_ar_ack <= 1'b0;
        end else begin
            if (m_ar_ack == 1'b0 && m_ar_req_sync[1] == 1'b1 && m_axil_arvalid && m_axil_arready)
                m_ar_ack <= 1'b1;
            if (m_ar_ack == 1'b1 && m_ar_ack_sync[1] == 1'b0)
                m_ar_ack <= 1'b0;
        end
    end

    // S-domain: set/clear s_ar_ack
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_ar_ack <= 1'b0;
        end else begin
            if (s_ar_ack == 1'b0 && s_ar_ack_sync[1] == 1'b1)
                s_ar_ack <= 1'b1;
            if (s_ar_ack == 1'b1 && s_ar_req == 1'b0)
                s_ar_ack <= 1'b0;
        end
    end

    // M-domain: sync s_ar_ack
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_ar_ack_sync <= 2'b00;
        else
            m_ar_ack_sync <= {m_ar_ack_sync[0], s_ar_ack};
    end

    // ========================================================================
    // Data registers for CDC
    // ========================================================================

    // Write Address data: captured in S-domain, read in M-domain
    reg [ADDR_WIDTH-1:0] s_awaddr_reg;
    reg [2:0]            s_awprot_reg;

    // Write Data: captured in S-domain, read in M-domain
    reg [DATA_WIDTH-1:0] s_wdata_reg;
    reg [STRB_WIDTH-1:0] s_wstrb_reg;

    // Write Response: captured in M-domain, read in S-domain
    reg [1:0] m_bresp_reg;

    // Read Address data: captured in S-domain, read in M-domain
    reg [ADDR_WIDTH-1:0] s_araddr_reg;
    reg [2:0]            s_arprot_reg;

    // Read Data: captured in M-domain, read in S-domain
    reg [DATA_WIDTH-1:0] m_rdata_reg;
    reg [1:0]            m_rresp_reg;

    // ========================================================================
    // S-domain: Capture data when accepting requests
    // ========================================================================
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_awaddr_reg <= {ADDR_WIDTH{1'b0}};
            s_awprot_reg <= 3'b000;
            s_wdata_reg  <= {DATA_WIDTH{1'b0}};
            s_wstrb_reg  <= {STRB_WIDTH{1'b0}};
            s_araddr_reg <= {ADDR_WIDTH{1'b0}};
            s_arprot_reg <= 3'b000;
        end else begin
            if (s_axil_awvalid && s_axil_awready) begin
                s_awaddr_reg <= s_axil_awaddr;
                s_awprot_reg <= s_axil_awprot;
            end
            if (s_axil_wvalid && s_axil_wready) begin
                s_wdata_reg <= s_axil_wdata;
                s_wstrb_reg <= s_axil_wstrb;
            end
            if (s_axil_arvalid && s_axil_arready) begin
                s_araddr_reg <= s_axil_araddr;
                s_arprot_reg <= s_axil_arprot;
            end
        end
    end

    // ========================================================================
    // M-domain: Capture response data
    // ========================================================================
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_bresp_reg <= 2'b00;
            m_rdata_reg <= {DATA_WIDTH{1'b0}};
            m_rresp_reg <= 2'b00;
        end else begin
            if (m_axil_bvalid)
                m_bresp_reg <= m_axil_bresp;
            if (m_axil_rvalid) begin
                m_rdata_reg <= m_axil_rdata;
                m_rresp_reg <= m_axil_rresp;
            end
        end
    end

    // ========================================================================
    // S-domain: AXI-Lite slave interface outputs
    // ========================================================================

    // AW ready: we can accept a new AW when we don't have a pending AW request
    assign s_axil_awready = (s_aw_req == 1'b0);

    // W ready: we can accept a new W when we don't have a pending W request
    assign s_axil_wready = (s_w_req == 1'b0);

    // B valid: we have a response from M-domain
    assign s_axil_bvalid = s_b_req_sync[1];
    assign s_axil_bresp  = m_bresp_reg;

    // AR ready: we can accept a new AR when we don't have a pending AR request
    assign s_axil_arready = (s_ar_req == 1'b0);

    // R valid: we have a response from M-domain
    assign s_axil_rvalid = s_r_req_sync[1];
    assign s_axil_rdata  = m_rdata_reg;
    assign s_axil_rresp  = m_rresp_reg;

    // ========================================================================
    // M-domain: AXI-Lite master interface outputs
    // ========================================================================

    // AW valid: we have a pending AW request from S-domain
    assign m_axil_awvalid = m_aw_req_sync[1];
    assign m_axil_awaddr  = s_awaddr_reg;
    assign m_axil_awprot  = s_awprot_reg;

    // W valid: we have a pending W request from S-domain
    assign m_axil_wvalid = m_w_req_sync[1];
    assign m_axil_wdata  = s_wdata_reg;
    assign m_axil_wstrb  = s_wstrb_reg;

    // B ready: we can accept a response when we don't have a pending B request
    assign m_axil_bready = (m_b_req == 1'b0);

    // AR valid: we have a pending AR request from S-domain
    assign m_axil_arvalid = m_ar_req_sync[1];
    assign m_axil_araddr  = s_araddr_reg;
    assign m_axil_arprot  = s_arprot_reg;

    // R ready: we can accept a response when we don't have a pending R request
    assign m_axil_rready = (m_r_req == 1'b0);

endmodule
