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
    reg [2:0] s_rst_sync;
    reg [2:0] m_rst_sync;

    always @(posedge s_clk) begin
        s_rst_sync <= {s_rst_sync[1:0], s_rst};
    end

    always @(posedge m_clk) begin
        m_rst_sync <= {m_rst_sync[1:0], m_rst};
    end

    wire s_rst_n = ~s_rst_sync[2];
    wire m_rst_n = ~m_rst_sync[2];

    // ========================================================================
    // Write Address Channel (AW): S -> M
    // ========================================================================
    // S-side: capture AW when valid and ready
    reg        s_aw_pending;
    reg [ADDR_WIDTH-1:0] s_aw_addr;
    reg [2:0]  s_aw_prot;

    // M-side: handshake
    reg        m_aw_valid;
    reg [ADDR_WIDTH-1:0] m_aw_addr;
    reg [2:0]  m_aw_prot;
    reg        m_aw_ready_int;

    // S-side: request to M
    reg        s_aw_req;
    reg [ADDR_WIDTH-1:0] s_aw_req_addr;
    reg [2:0]  s_aw_req_prot;

    // M-side: acknowledge to S
    reg        m_aw_ack;
    reg        m_aw_ack_sync;
    reg        m_aw_ack_sync2;

    // S-side: acknowledge sync
    reg        s_aw_ack_sync;
    reg        s_aw_ack_sync2;

    // M-side: request sync
    reg        m_aw_req_sync;
    reg        m_aw_req_sync2;
    reg [ADDR_WIDTH-1:0] m_aw_req_addr_sync;
    reg [ADDR_WIDTH-1:0] m_aw_req_addr_sync2;
    reg [2:0]  m_aw_req_prot_sync;
    reg [2:0]  m_aw_req_prot_sync2;

    // S-side: request data (stable while s_aw_req is high)
    assign s_aw_req_addr = s_aw_addr;
    assign s_aw_req_prot = s_aw_prot;

    // M-side: sync request
    always @(posedge m_clk) begin
        m_aw_req_sync <= s_aw_req;
        m_aw_req_sync2 <= m_aw_req_sync;
        if (m_aw_req_sync) begin
            m_aw_req_addr_sync <= s_aw_req_addr;
            m_aw_req_prot_sync <= s_aw_req_prot;
        end
        if (m_aw_req_sync2) begin
            m_aw_req_addr_sync2 <= m_aw_req_addr_sync;
            m_aw_req_prot_sync2 <= m_aw_req_prot_sync;
        end
    end

    // M-side: process request
    always @(posedge m_clk) begin
        if (!m_rst_n) begin
            m_aw_valid <= 1'b0;
            m_aw_addr <= {ADDR_WIDTH{1'b0}};
            m_aw_prot <= 3'b000;
            m_aw_ready_int <= 1'b0;
            m_aw_ack <= 1'b0;
        end else begin
            if (m_aw_req_sync2 && !m_aw_valid) begin
                m_aw_valid <= 1'b1;
                m_aw_addr <= m_aw_req_addr_sync2;
                m_aw_prot <= m_aw_req_prot_sync2;
                m_aw_ready_int <= 1'b0;
            end
            if (m_aw_valid && m_axil_awready) begin
                m_aw_valid <= 1'b0;
                m_aw_ready_int <= 1'b1;
            end
            if (m_aw_ready_int) begin
                m_aw_ready_int <= 1'b0;
                m_aw_ack <= 1'b1;
            end
            if (m_aw_ack) begin
                m_aw_ack <= 1'b0;
            end
        end
    end

    // S-side: sync acknowledge
    always @(posedge s_clk) begin
        s_aw_ack_sync <= m_aw_ack;
        s_aw_ack_sync2 <= s_aw_ack_sync;
    end

    // S-side: process acknowledge
    always @(posedge s_clk) begin
        if (!s_rst_n) begin
            s_aw_pending <= 1'b0;
            s_aw_addr <= {ADDR_WIDTH{1'b0}};
            s_aw_prot <= 3'b000;
            s_aw_req <= 1'b0;
        end else begin
            if (s_axil_awvalid && s_axil_awready) begin
                s_aw_pending <= 1'b1;
                s_aw_addr <= s_axil_awaddr;
                s_aw_prot <= s_axil_awprot;
                s_aw_req <= 1'b1;
            end
            if (s_aw_pending && s_aw_ack_sync2) begin
                s_aw_pending <= 1'b0;
                s_aw_req <= 1'b0;
            end
        end
    end

    assign s_axil_awready = !s_aw_pending;
    assign m_axil_awaddr = m_aw_addr;
    assign m_axil_awprot = m_aw_prot;
    assign m_axil_awvalid = m_aw_valid;

    // ========================================================================
    // Write Data Channel (W): S -> M
    // ========================================================================
    reg        s_w_pending;
    reg [DATA_WIDTH-1:0] s_w_data;
    reg [STRB_WIDTH-1:0] s_w_strb;

    reg        m_w_valid;
    reg [DATA_WIDTH-1:0] m_w_data;
    reg [STRB_WIDTH-1:0] m_w_strb;
    reg        m_w_ready_int;

    reg        s_w_req;
    reg [DATA_WIDTH-1:0] s_w_req_data;
    reg [STRB_WIDTH-1:0] s_w_req_strb;

    reg        m_w_ack;
    reg        m_w_ack_sync;
    reg        m_w_ack_sync2;

    reg        s_w_ack_sync;
    reg        s_w_ack_sync2;

    reg        m_w_req_sync;
    reg        m_w_req_sync2;
    reg [DATA_WIDTH-1:0] m_w_req_data_sync;
    reg [DATA_WIDTH-1:0] m_w_req_data_sync2;
    reg [STRB_WIDTH-1:0] m_w_req_strb_sync;
    reg [STRB_WIDTH-1:0] m_w_req_strb_sync2;

    assign s_w_req_data = s_w_data;
    assign s_w_req_strb = s_w_strb;

    always @(posedge m_clk) begin
        m_w_req_sync <= s_w_req;
        m_w_req_sync2 <= m_w_req_sync;
        if (m_w_req_sync) begin
            m_w_req_data_sync <= s_w_req_data;
            m_w_req_strb_sync <= s_w_req_strb;
        end
        if (m_w_req_sync2) begin
            m_w_req_data_sync2 <= m_w_req_data_sync;
            m_w_req_strb_sync2 <= m_w_req_strb_sync;
        end
    end

    always @(posedge m_clk) begin
        if (!m_rst_n) begin
            m_w_valid <= 1'b0;
            m_w_data <= {DATA_WIDTH{1'b0}};
            m_w_strb <= {STRB_WIDTH{1'b0}};
            m_w_ready_int <= 1'b0;
            m_w_ack <= 1'b0;
        end else begin
            if (m_w_req_sync2 && !m_w_valid) begin
                m_w_valid <= 1'b1;
                m_w_data <= m_w_req_data_sync2;
                m_w_strb <= m_w_req_strb_sync2;
                m_w_ready_int <= 1'b0;
            end
            if (m_w_valid && m_axil_wready) begin
                m_w_valid <= 1'b0;
                m_w_ready_int <= 1'b1;
            end
            if (m_w_ready_int) begin
                m_w_ready_int <= 1'b0;
                m_w_ack <= 1'b1;
            end
            if (m_w_ack) begin
                m_w_ack <= 1'b0;
            end
        end
    end

    always @(posedge s_clk) begin
        s_w_ack_sync <= m_w_ack;
        s_w_ack_sync2 <= s_w_ack_sync;
    end

    always @(posedge s_clk) begin
        if (!s_rst_n) begin
            s_w_pending <= 1'b0;
            s_w_data <= {DATA_WIDTH{1'b0}};
            s_w_strb <= {STRB_WIDTH{1'b0}};
            s_w_req <= 1'b0;
        end else begin
            if (s_axil_wvalid && s_axil_wready) begin
                s_w_pending <= 1'b1;
                s_w_data <= s_axil_wdata;
                s_w_strb <= s_axil_wstrb;
                s_w_req <= 1'b1;
            end
            if (s_w_pending && s_w_ack_sync2) begin
                s_w_pending <= 1'b0;
                s_w_req <= 1'b0;
            end
        end
    end

    assign s_axil_wready = !s_w_pending;
    assign m_axil_wdata = m_w_data;
    assign m_axil_wstrb = m_w_strb;
    assign m_axil_wvalid = m_w_valid;

    // ========================================================================
    // Write Response Channel (B): M -> S
    // ========================================================================
    reg        m_b_pending;
    reg [1:0]  m_b_resp;

    reg        s_b_valid;
    reg [1:0]  s_b_resp;
    reg        s_b_ready_int;

    reg        m_b_req;
    reg [1:0]  m_b_req_resp;

    reg        s_b_ack;
    reg        s_b_ack_sync;
    reg        s_b_ack_sync2;

    reg        m_b_ack_sync;
    reg        m_b_ack_sync2;

    reg        s_b_req_sync;
    reg        s_b_req_sync2;
    reg [1:0]  s_b_req_resp_sync;
    reg [1:0]  s_b_req_resp_sync2;

    assign m_b_req_resp = m_b_resp;

    always @(posedge s_clk) begin
        s_b_req_sync <= m_b_req;
        s_b_req_sync2 <= s_b_req_sync;
        if (s_b_req_sync) begin
            s_b_req_resp_sync <= m_b_req_resp;
        end
        if (s_b_req_sync2) begin
            s_b_req_resp_sync2 <= s_b_req_resp_sync;
        end
    end

    always @(posedge s_clk) begin
        if (!s_rst_n) begin
            s_b_valid <= 1'b0;
            s_b_resp <= 2'b00;
            s_b_ready_int <= 1'b0;
            s_b_ack <= 1'b0;
        end else begin
            if (s_b_req_sync2 && !s_b_valid) begin
                s_b_valid <= 1'b1;
                s_b_resp <= s_b_req_resp_sync2;
                s_b_ready_int <= 1'b0;
            end
            if (s_b_valid && s_axil_bready) begin
                s_b_valid <= 1'b0;
                s_b_ready_int <= 1'b1;
            end
            if (s_b_ready_int) begin
                s_b_ready_int <= 1'b0;
                s_b_ack <= 1'b1;
            end
            if (s_b_ack) begin
                s_b_ack <= 1'b0;
            end
        end
    end

    always @(posedge m_clk) begin
        m_b_ack_sync <= s_b_ack;
        m_b_ack_sync2 <= m_b_ack_sync;
    end

    always @(posedge m_clk) begin
        if (!m_rst_n) begin
            m_b_pending <= 1'b0;
            m_b_resp <= 2'b00;
            m_b_req <= 1'b0;
        end else begin
            if (m_axil_bvalid && m_axil_bready) begin
                m_b_pending <= 1'b1;
                m_b_resp <= m_axil_bresp;
                m_b_req <= 1'b1;
            end
            if (m_b_pending && m_b_ack_sync2) begin
                m_b_pending <= 1'b0;
                m_b_req <= 1'b0;
            end
        end
    end

    assign s_axil_bresp = s_b_resp;
    assign s_axil_bvalid = s_b_valid;
    assign m_axil_bready = !m_b_pending;

    // ========================================================================
    // Read Address Channel (AR): S -> M
    // ========================================================================
    reg        s_ar_pending;
    reg [ADDR_WIDTH-1:0] s_ar_addr;
    reg [2:0]  s_ar_prot;

    reg        m_ar_valid;
    reg [ADDR_WIDTH-1:0] m_ar_addr;
    reg [2:0]  m_ar_prot;
    reg        m_ar_ready_int;

    reg        s_ar_req;
    reg [ADDR_WIDTH-1:0] s_ar_req_addr;
    reg [2:0]  s_ar_req_prot;

    reg        m_ar_ack;
    reg        m_ar_ack_sync;
    reg        m_ar_ack_sync2;

    reg        s_ar_ack_sync;
    reg        s_ar_ack_sync2;

    reg        m_ar_req_sync;
    reg        m_ar_req_sync2;
    reg [ADDR_WIDTH-1:0] m_ar_req_addr_sync;
    reg [ADDR_WIDTH-1:0] m_ar_req_addr_sync2;
    reg [2:0]  m_ar_req_prot_sync;
    reg [2:0]  m_ar_req_prot_sync2;

    assign s_ar_req_addr = s_ar_addr;
    assign s_ar_req_prot = s_ar_prot;

    always @(posedge m_clk) begin
        m_ar_req_sync <= s_ar_req;
        m_ar_req_sync2 <= m_ar_req_sync;
        if (m_ar_req_sync) begin
            m_ar_req_addr_sync <= s_ar_req_addr;
            m_ar_req_prot_sync <= s_ar_req_prot;
        end
        if (m_ar_req_sync2) begin
            m_ar_req_addr_sync2 <= m_ar_req_addr_sync;
            m_ar_req_prot_sync2 <= m_ar_req_prot_sync;
        end
    end

    always @(posedge m_clk) begin
        if (!m_rst_n) begin
            m_ar_valid <= 1'b0;
            m_ar_addr <= {ADDR_WIDTH{1'b0}};
            m_ar_prot <= 3'b000;
            m_ar_ready_int <= 1'b0;
            m_ar_ack <= 1'b0;
        end else begin
            if (m_ar_req_sync2 && !m_ar_valid) begin
                m_ar_valid <= 1'b1;
                m_ar_addr <= m_ar_req_addr_sync2;
                m_ar_prot <= m_ar_req_prot_sync2;
                m_ar_ready_int <= 1'b0;
            end
            if (m_ar_valid && m_axil_arready) begin
                m_ar_valid <= 1'b0;
                m_ar_ready_int <= 1'b1;
            end
            if (m_ar_ready_int) begin
                m_ar_ready_int <= 1'b0;
                m_ar_ack <= 1'b1;
            end
            if (m_ar_ack) begin
                m_ar_ack <= 1'b0;
            end
        end
    end

    always @(posedge s_clk) begin
        s_ar_ack_sync <= m_ar_ack;
        s_ar_ack_sync2 <= s_ar_ack_sync;
    end

    always @(posedge s_clk) begin
        if (!s_rst_n) begin
            s_ar_pending <= 1'b0;
            s_ar_addr <= {ADDR_WIDTH{1'b0}};
            s_ar_prot <= 3'b000;
            s_ar_req <= 1'b0;
        end else begin
            if (s_axil_arvalid && s_axil_arready) begin
                s_ar_pending <= 1'b1;
                s_ar_addr <= s_axil_araddr;
                s_ar_prot <= s_axil_arprot;
                s_ar_req <= 1'b1;
            end
            if (s_ar_pending && s_ar_ack_sync2) begin
                s_ar_pending <= 1'b0;
                s_ar_req <= 1'b0;
            end
        end
    end

    assign s_axil_arready = !s_ar_pending;
    assign m_axil_araddr = m_ar_addr;
    assign m_axil_arprot = m_ar_prot;
    assign m_axil_arvalid = m_ar_valid;

    // ========================================================================
    // Read Data Channel (R): M -> S
    // ========================================================================
    reg        m_r_pending;
    reg [DATA_WIDTH-1:0] m_r_data;
    reg [1:0]  m_r_resp;

    reg        s_r_valid;
    reg [DATA_WIDTH-1:0] s_r_data;
    reg [1:0]  s_r_resp;
    reg        s_r_ready_int;

    reg        m_r_req;
    reg [DATA_WIDTH-1:0] m_r_req_data;
    reg [1:0]  m_r_req_resp;

    reg        s_r_ack;
    reg        s_r_ack_sync;
    reg        s_r_ack_sync2;

    reg        m_r_ack_sync;
    reg        m_r_ack_sync2;

    reg        s_r_req_sync;
    reg        s_r_req_sync2;
    reg [DATA_WIDTH-1:0] s_r_req_data_sync;
    reg [DATA_WIDTH-1:0] s_r_req_data_sync2;
    reg [1:0]  s_r_req_resp_sync;
    reg [1:0]  s_r_req_resp_sync2;

    assign m_r_req_data = m_r_data;
    assign m_r_req_resp = m_r_resp;

    always @(posedge s_clk) begin
        s_r_req_sync <= m_r_req;
        s_r_req_sync2 <= s_r_req_sync;
        if (s_r_req_sync) begin
            s_r_req_data_sync <= m_r_req_data;
            s_r_req_resp_sync <= m_r_req_resp;
        end
        if (s_r_req_sync2) begin
            s_r_req_data_sync2 <= s_r_req_data_sync;
            s_r_req_resp_sync2 <= s_r_req_resp_sync;
        end
    end

    always @(posedge s_clk) begin
        if (!s_rst_n) begin
            s_r_valid <= 1'b0;
            s_r_data <= {DATA_WIDTH{1'b0}};
            s_r_resp <= 2'b00;
            s_r_ready_int <= 1'b0;
            s_r_ack <= 1'b0;
        end else begin
            if (s_r_req_sync2 && !s_r_valid) begin
                s_r_valid <= 1'b1;
                s_r_data <= s_r_req_data_sync2;
                s_r_resp <= s_r_req_resp_sync2;
                s_r_ready_int <= 1'b0;
            end
            if (s_r_valid && s_axil_rready) begin
                s_r_valid <= 1'b0;
                s_r_ready_int <= 1'b1;
            end
            if (s_r_ready_int) begin
                s_r_ready_int <= 1'b0;
                s_r_ack <= 1'b1;
            end
            if (s_r_ack) begin
                s_r_ack <= 1'b0;
            end
        end
    end

    always @(posedge m_clk) begin
        m_r_ack_sync <= s_r_ack;
        m_r_ack_sync2 <= m_r_ack_sync;
    end

    always @(posedge m_clk) begin
        if (!m_rst_n) begin
            m_r_pending <= 1'b0;
            m_r_data <= {DATA_WIDTH{1'b0}};
            m_r_resp <= 2'b00;
            m_r_req <= 1'b0;
        end else begin
            if (m_axil_rvalid && m_axil_rready) begin
                m_r_pending <= 1'b1;
                m_r_data <= m_axil_rdata;
                m_r_resp <= m_axil_rresp;
                m_r_req <= 1'b1;
            end
            if (m_r_pending && m_r_ack_sync2) begin
                m_r_pending <= 1'b0;
                m_r_req <= 1'b0;
            end
        end
    end

    assign s_axil_rdata = s_r_data;
    assign s_axil_rresp = s_r_resp;
    assign s_axil_rvalid = s_r_valid;
    assign m_axil_rready = !m_r_pending;

endmodule
