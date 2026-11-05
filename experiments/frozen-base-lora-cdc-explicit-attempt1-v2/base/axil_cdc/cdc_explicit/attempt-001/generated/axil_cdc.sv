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
    // Write Address Channel: S -> M
    // ========================================================================
    reg  [ADDR_WIDTH-1:0] s_awaddr_reg;
    reg  [2:0]            s_awprot_reg;
    reg                   s_aw_req;
    reg                   s_aw_ack;
    reg                   s_aw_ack_sync1;
    reg                   s_aw_ack_sync2;

    wire s_aw_handshake = s_axil_awvalid & s_axil_awready;

    assign s_axil_awready = ~s_aw_req | s_aw_ack_sync2;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_awaddr_reg   <= {ADDR_WIDTH{1'b0}};
            s_awprot_reg   <= 3'b000;
            s_aw_req       <= 1'b0;
            s_aw_ack       <= 1'b0;
            s_aw_ack_sync1 <= 1'b0;
            s_aw_ack_sync2 <= 1'b0;
        end else begin
            s_aw_ack_sync1 <= s_aw_ack;
            s_aw_ack_sync2 <= s_aw_ack_sync1;

            if (s_aw_handshake) begin
                s_awaddr_reg <= s_axil_awaddr;
                s_awprot_reg <= s_axil_awprot;
                s_aw_req     <= 1'b1;
                s_aw_ack     <= 1'b0;
            end else if (s_aw_req & s_aw_ack_sync2) begin
                s_aw_req <= 1'b0;
            end
        end
    end

    // Synchronize s_aw_req to M domain
    reg m_aw_req_sync1;
    reg m_aw_req_sync2;
    reg m_aw_ack;
    reg m_aw_ack_sync1;
    reg m_aw_ack_sync2;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_aw_req_sync1 <= 1'b0;
            m_aw_req_sync2 <= 1'b0;
            m_aw_ack       <= 1'b0;
            m_aw_ack_sync1 <= 1'b0;
            m_aw_ack_sync2 <= 1'b0;
        end else begin
            m_aw_req_sync1 <= s_aw_req;
            m_aw_req_sync2 <= m_aw_req_sync1;

            if (m_aw_req_sync2 & ~m_aw_ack) begin
                m_aw_ack <= 1'b1;
            end
        end
    end

    // Synchronize m_aw_ack to S domain
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_aw_ack_sync1 <= 1'b0;
            s_aw_ack_sync2 <= 1'b0;
        end else begin
            s_aw_ack_sync1 <= m_aw_ack;
            s_aw_ack_sync2 <= s_aw_ack_sync1;
        end
    end

    // M side: hold payload stable, present when req is high
    assign m_axil_awaddr  = s_awaddr_reg;
    assign m_axil_awprot  = s_awprot_reg;
    assign m_axil_awvalid = m_aw_req_sync2;

    // ========================================================================
    // Write Data Channel: S -> M
    // ========================================================================
    reg  [DATA_WIDTH-1:0] s_wdata_reg;
    reg  [STRB_WIDTH-1:0] s_wstrb_reg;
    reg                   s_w_req;
    reg                   s_w_ack;
    reg                   s_w_ack_sync1;
    reg                   s_w_ack_sync2;

    wire s_w_handshake = s_axil_wvalid & s_axil_wready;

    assign s_axil_wready = ~s_w_req | s_w_ack_sync2;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wdata_reg    <= {DATA_WIDTH{1'b0}};
            s_wstrb_reg    <= {STRB_WIDTH{1'b0}};
            s_w_req        <= 1'b0;
            s_w_ack        <= 1'b0;
            s_w_ack_sync1  <= 1'b0;
            s_w_ack_sync2  <= 1'b0;
        end else begin
            s_w_ack_sync1 <= s_w_ack;
            s_w_ack_sync2 <= s_w_ack_sync1;

            if (s_w_handshake) begin
                s_wdata_reg <= s_axil_wdata;
                s_wstrb_reg <= s_axil_wstrb;
                s_w_req     <= 1'b1;
                s_w_ack     <= 1'b0;
            end else if (s_w_req & s_w_ack_sync2) begin
                s_w_req <= 1'b0;
            end
        end
    end

    // Synchronize s_w_req to M domain
    reg m_w_req_sync1;
    reg m_w_req_sync2;
    reg m_w_ack;
    reg m_w_ack_sync1;
    reg m_w_ack_sync2;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_w_req_sync1 <= 1'b0;
            m_w_req_sync2 <= 1'b0;
            m_w_ack       <= 1'b0;
            m_w_ack_sync1 <= 1'b0;
            m_w_ack_sync2 <= 1'b0;
        end else begin
            m_w_req_sync1 <= s_w_req;
            m_w_req_sync2 <= m_w_req_sync1;

            if (m_w_req_sync2 & ~m_w_ack) begin
                m_w_ack <= 1'b1;
            end
        end
    end

    // Synchronize m_w_ack to S domain
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_w_ack_sync1 <= 1'b0;
            s_w_ack_sync2 <= 1'b0;
        end else begin
            s_w_ack_sync1 <= m_w_ack;
            s_w_ack_sync2 <= m_w_ack_sync1;
        end
    end

    assign m_axil_wdata  = s_wdata_reg;
    assign m_axil_wstrb  = s_wstrb_reg;
    assign m_axil_wvalid = m_w_req_sync2;

    // ========================================================================
    // Write Response Channel: M -> S
    // ========================================================================
    reg  [1:0] m_bresp_reg;
    reg        m_b_req;
    reg        m_b_ack;
    reg        m_b_ack_sync1;
    reg        m_b_ack_sync2;

    wire m_b_handshake = m_axil_bvalid & m_axil_bready;

    assign m_axil_bready = ~m_b_req | m_b_ack_sync2;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_bresp_reg    <= 2'b00;
            m_b_req        <= 1'b0;
            m_b_ack        <= 1'b0;
            m_b_ack_sync1  <= 1'b0;
            m_b_ack_sync2  <= 1'b0;
        end else begin
            m_b_ack_sync1 <= m_b_ack;
            m_b_ack_sync2 <= m_b_ack_sync1;

            if (m_b_handshake) begin
                m_bresp_reg <= m_axil_bresp;
                m_b_req     <= 1'b1;
                m_b_ack     <= 1'b0;
            end else if (m_b_req & m_b_ack_sync2) begin
                m_b_req <= 1'b0;
            end
        end
    end

    // Synchronize m_b_req to S domain
    reg s_b_req_sync1;
    reg s_b_req_sync2;
    reg s_b_ack;
    reg s_b_ack_sync1;
    reg s_b_ack_sync2;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_b_req_sync1 <= 1'b0;
            s_b_req_sync2 <= 1'b0;
            s_b_ack       <= 1'b0;
            s_b_ack_sync1 <= 1'b0;
            s_b_ack_sync2 <= 1'b0;
        end else begin
            s_b_req_sync1 <= m_b_req;
            s_b_req_sync2 <= s_b_req_sync1;

            if (s_b_req_sync2 & ~s_b_ack) begin
                s_b_ack <= 1'b1;
            end
        end
    end

    // Synchronize s_b_ack to M domain
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_b_ack_sync1 <= 1'b0;
            m_b_ack_sync2 <= 1'b0;
        end else begin
            m_b_ack_sync1 <= s_b_ack;
            m_b_ack_sync2 <= m_b_ack_sync1;
        end
    end

    assign s_axil_bresp  = m_bresp_reg;
    assign s_axil_bvalid = s_b_req_sync2;

    // ========================================================================
    // Read Address Channel: S -> M
    // ========================================================================
    reg  [ADDR_WIDTH-1:0] s_araddr_reg;
    reg  [2:0]            s_arprot_reg;
    reg                   s_ar_req;
    reg                   s_ar_ack;
    reg                   s_ar_ack_sync1;
    reg                   s_ar_ack_sync2;

    wire s_ar_handshake = s_axil_arvalid & s_axil_arready;

    assign s_axil_arready = ~s_ar_req | s_ar_ack_sync2;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_araddr_reg   <= {ADDR_WIDTH{1'b0}};
            s_arprot_reg   <= 3'b000;
            s_ar_req       <= 1'b0;
            s_ar_ack       <= 1'b0;
            s_ar_ack_sync1 <= 1'b0;
            s_ar_ack_sync2 <= 1'b0;
        end else begin
            s_ar_ack_sync1 <= s_ar_ack;
            s_ar_ack_sync2 <= s_ar_ack_sync1;

            if (s_ar_handshake) begin
                s_araddr_reg <= s_axil_araddr;
                s_arprot_reg <= s_axil_arprot;
                s_ar_req     <= 1'b1;
                s_ar_ack     <= 1'b0;
            end else if (s_ar_req & s_ar_ack_sync2) begin
                s_ar_req <= 1'b0;
            end
        end
    end

    // Synchronize s_ar_req to M domain
    reg m_ar_req_sync1;
    reg m_ar_req_sync2;
    reg m_ar_ack;
    reg m_ar_ack_sync1;
    reg m_ar_ack_sync2;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_ar_req_sync1 <= 1'b0;
            m_ar_req_sync2 <= 1'b0;
            m_ar_ack       <= 1'b0;
            m_ar_ack_sync1 <= 1'b0;
            m_ar_ack_sync2 <= 1'b0;
        end else begin
            m_ar_req_sync1 <= s_ar_req;
            m_ar_req_sync2 <= m_ar_req_sync1;

            if (m_ar_req_sync2 & ~m_ar_ack) begin
                m_ar_ack <= 1'b1;
            end
        end
    end

    // Synchronize m_ar_ack to S domain
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_ar_ack_sync1 <= 1'b0;
            s_ar_ack_sync2 <= 1'b0;
        end else begin
            s_ar_ack_sync1 <= m_ar_ack;
            s_ar_ack_sync2 <= m_ar_ack_sync1;
        end
    end

    assign m_axil_araddr  = s_araddr_reg;
    assign m_axil_arprot  = s_arprot_reg;
    assign m_axil_arvalid = m_ar_req_sync2;

    // ========================================================================
    // Read Data Channel: M -> S
    // ========================================================================
    reg  [DATA_WIDTH-1:0] m_rdata_reg;
    reg  [1:0]            m_rresp_reg;
    reg                   m_r_req;
    reg                   m_r_ack;
    reg                   m_r_ack_sync1;
    reg                   m_r_ack_sync2;

    wire m_r_handshake = m_axil_rvalid & m_axil_rready;

    assign m_axil_rready = ~m_r_req | m_r_ack_sync2;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rdata_reg    <= {DATA_WIDTH{1'b0}};
            m_rresp_reg    <= 2'b00;
            m_r_req        <= 1'b0;
            m_r_ack        <= 1'b0;
            m_r_ack_sync1  <= 1'b0;
            m_r_ack_sync2  <= 1'b0;
        end else begin
            m_r_ack_sync1 <= m_r_ack;
            m_r_ack_sync2 <= m_r_ack_sync1;

            if (m_r_handshake) begin
                m_rdata_reg <= m_axil_rdata;
                m_rresp_reg <= m_axil_rresp;
                m_r_req     <= 1'b1;
                m_r_ack     <= 1'b0;
            end else if (m_r_req & m_r_ack_sync2) begin
                m_r_req <= 1'b0;
            end
        end
    end

    // Synchronize m_r_req to S domain
    reg s_r_req_sync1;
    reg s_r_req_sync2;
    reg s_r_ack;
    reg s_r_ack_sync1;
    reg s_r_ack_sync2;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_r_req_sync1 <= 1'b0;
            s_r_req_sync2 <= 1'b0;
            s_r_ack       <= 1'b0;
            s_r_ack_sync1 <= 1'b0;
            s_r_ack_sync2 <= 1'b0;
        end else begin
            s_r_req_sync1 <= m_r_req;
            s_r_req_sync2 <= s_r_req_sync1;

            if (s_r_req_sync2 & ~s_r_ack) begin
                s_r_ack <= 1'b1;
            end
        end
    end

    // Synchronize s_r_ack to M domain
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_r_ack_sync1 <= 1'b0;
            m_r_ack_sync2 <= 1'b0;
        end else begin
            m_r_ack_sync1 <= s_r_ack;
            m_r_ack_sync2 <= m_r_ack_sync1;
        end
    end

    assign s_axil_rdata  = m_rdata_reg;
    assign s_axil_rresp  = m_rresp_reg;
    assign s_axil_rvalid = s_r_req_sync2;

endmodule
