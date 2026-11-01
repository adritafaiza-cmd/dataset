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

    // Slave side state
    reg  s_aw_pending;
    reg  s_w_pending;
    reg  s_ar_pending;
    reg  s_b_pending;
    reg  s_r_pending;

    // Slave side data registers
    reg  [ADDR_WIDTH-1:0] s_awaddr_reg;
    reg  [2:0]            s_awprot_reg;
    reg  [DATA_WIDTH-1:0] s_wdata_reg;
    reg  [STRB_WIDTH-1:0] s_wstrb_reg;
    reg  [ADDR_WIDTH-1:0] s_araddr_reg;
    reg  [2:0]            s_arprot_reg;
    reg  [DATA_WIDTH-1:0] s_rdata_reg;
    reg  [1:0]            s_rresp_reg;
    reg  [1:0]            s_bresp_reg;

    // Master side state
    reg  m_aw_pending;
    reg  m_w_pending;
    reg  m_ar_pending;
    reg  m_b_pending;
    reg  m_r_pending;

    // Master side data registers
    reg  [ADDR_WIDTH-1:0] m_awaddr_reg;
    reg  [2:0]            m_awprot_reg;
    reg  [DATA_WIDTH-1:0] m_wdata_reg;
    reg  [STRB_WIDTH-1:0] m_wstrb_reg;
    reg  [ADDR_WIDTH-1:0] m_araddr_reg;
    reg  [2:0]            m_arprot_reg;
    reg  [DATA_WIDTH-1:0] m_rdata_reg;
    reg  [1:0]            m_rresp_reg;
    reg  [1:0]            m_bresp_reg;

    // CDC handshake signals (slave -> master)
    wire s_aw_req;
    wire s_aw_ack;
    wire s_w_req;
    wire s_w_ack;
    wire s_ar_req;
    wire s_ar_ack;

    // CDC handshake signals (master -> slave)
    wire m_b_req;
    wire m_b_ack;
    wire m_r_req;
    wire m_r_ack;

    // ========================================================================
    // Slave Clock Domain Logic
    // ========================================================================

    // AW channel: accept when not pending
    assign s_axil_awready = ~s_aw_pending;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_aw_pending <= 1'b0;
            s_awaddr_reg <= {ADDR_WIDTH{1'b0}};
            s_awprot_reg <= 3'b000;
        end else begin
            if (s_axil_awvalid && s_axil_awready) begin
                s_aw_pending <= 1'b1;
                s_awaddr_reg <= s_axil_awaddr;
                s_awprot_reg <= s_axil_awprot;
            end else if (s_aw_pending && s_aw_ack) begin
                s_aw_pending <= 1'b0;
            end
        end
    end

    // W channel: accept when not pending
    assign s_axil_wready = ~s_w_pending;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_w_pending <= 1'b0;
            s_wdata_reg <= {DATA_WIDTH{1'b0}};
            s_wstrb_reg <= {STRB_WIDTH{1'b0}};
        end else begin
            if (s_axil_wvalid && s_axil_wready) begin
                s_w_pending <= 1'b1;
                s_wdata_reg <= s_axil_wdata;
                s_wstrb_reg <= s_axil_wstrb;
            end else if (s_w_pending && s_w_ack) begin
                s_w_pending <= 1'b0;
            end
        end
    end

    // AR channel: accept when not pending
    assign s_axil_arready = ~s_ar_pending;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_ar_pending <= 1'b0;
            s_araddr_reg <= {ADDR_WIDTH{1'b0}};
            s_arprot_reg <= 3'b000;
        end else begin
            if (s_axil_arvalid && s_axil_arready) begin
                s_ar_pending <= 1'b1;
                s_araddr_reg <= s_axil_araddr;
                s_arprot_reg <= s_axil_arprot;
            end else if (s_ar_pending && s_ar_ack) begin
                s_ar_pending <= 1'b0;
            end
        end
    end

    // B channel: respond when master sends B
    assign s_axil_bvalid = s_b_pending;
    assign s_axil_bresp  = s_bresp_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_b_pending <= 1'b0;
            s_bresp_reg <= 2'b00;
        end else begin
            if (m_b_req && ~s_b_pending) begin
                s_b_pending <= 1'b1;
                s_bresp_reg <= m_bresp_reg;
            end else if (s_b_pending && s_axil_bready) begin
                s_b_pending <= 1'b0;
            end
        end
    end

    // R channel: respond when master sends R
    assign s_axil_rvalid = s_r_pending;
    assign s_axil_rdata  = s_rdata_reg;
    assign s_axil_rresp  = s_rresp_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_r_pending <= 1'b0;
            s_rdata_reg <= {DATA_WIDTH{1'b0}};
            s_rresp_reg <= 2'b00;
        end else begin
            if (m_r_req && ~s_r_pending) begin
                s_r_pending <= 1'b1;
                s_rdata_reg <= m_rdata_reg;
                s_rresp_reg <= m_rresp_reg;
            end else if (s_r_pending && s_axil_rready) begin
                s_r_pending <= 1'b0;
            end
        end
    end

    // ========================================================================
    // Master Clock Domain Logic
    // ========================================================================

    // AW channel: drive when pending
    assign m_axil_awvalid = m_aw_pending;
    assign m_axil_awaddr  = m_awaddr_reg;
    assign m_axil_awprot  = m_awprot_reg;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_aw_pending <= 1'b0;
            m_awaddr_reg <= {ADDR_WIDTH{1'b0}};
            m_awprot_reg <= 3'b000;
        end else begin
            if (s_aw_req && ~m_aw_pending) begin
                m_aw_pending <= 1'b1;
                m_awaddr_reg <= s_awaddr_reg;
                m_awprot_reg <= s_awprot_reg;
            end else if (m_aw_pending && m_axil_awready) begin
                m_aw_pending <= 1'b0;
            end
        end
    end

    // W channel: drive when pending
    assign m_axil_wvalid = m_w_pending;
    assign m_axil_wdata  = m_wdata_reg;
    assign m_axil_wstrb  = m_wstrb_reg;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_w_pending <= 1'b0;
            m_wdata_reg <= {DATA_WIDTH{1'b0}};
            m_wstrb_reg <= {STRB_WIDTH{1'b0}};
        end else begin
            if (s_w_req && ~m_w_pending) begin
                m_w_pending <= 1'b1;
                m_wdata_reg <= s_wdata_reg;
                m_wstrb_reg <= s_wstrb_reg;
            end else if (m_w_pending && m_axil_wready) begin
                m_w_pending <= 1'b0;
            end
        end
    end

    // AR channel: drive when pending
    assign m_axil_arvalid = m_ar_pending;
    assign m_axil_araddr  = m_araddr_reg;
    assign m_axil_arprot  = m_arprot_reg;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_ar_pending <= 1'b0;
            m_araddr_reg <= {ADDR_WIDTH{1'b0}};
            m_arprot_reg <= 3'b000;
        end else begin
            if (s_ar_req && ~m_ar_pending) begin
                m_ar_pending <= 1'b1;
                m_araddr_reg <= s_araddr_reg;
                m_arprot_reg <= s_arprot_reg;
            end else if (m_ar_pending && m_axil_arready) begin
                m_ar_pending <= 1'b0;
            end
        end
    end

    // B channel: accept when not pending
    assign m_axil_bready = ~m_b_pending;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_b_pending <= 1'b0;
            m_bresp_reg <= 2'b00;
        end else begin
            if (m_axil_bvalid && m_axil_bready) begin
                m_b_pending <= 1'b1;
                m_bresp_reg <= m_axil_bresp;
            end else if (m_b_pending && m_b_ack) begin
                m_b_pending <= 1'b0;
            end
        end
    end

    // R channel: accept when not pending
    assign m_axil_rready = ~m_r_pending;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_r_pending <= 1'b0;
            m_rdata_reg <= {DATA_WIDTH{1'b0}};
            m_rresp_reg <= 2'b00;
        end else begin
            if (m_axil_rvalid && m_axil_rready) begin
                m_r_pending <= 1'b1;
                m_rdata_reg <= m_axil_rdata;
                m_rresp_reg <= m_axil_rresp;
            end else if (m_r_pending && m_r_ack) begin
                m_r_pending <= 1'b0;
            end
        end
    end

    // ========================================================================
    // CDC Handshake: Slave -> Master (AW, W, AR)
    // ========================================================================

    // AW handshake
    assign s_aw_req = s_aw_pending;
    assign s_aw_ack = m_aw_pending;

    // W handshake
    assign s_w_req = s_w_pending;
    assign s_w_ack = m_w_pending;

    // AR handshake
    assign s_ar_req = s_ar_pending;
    assign s_ar_ack = m_ar_pending;

    // ========================================================================
    // CDC Handshake: Master -> Slave (B, R)
    // ========================================================================

    // B handshake
    assign m_b_req = m_b_pending;
    assign m_b_ack = s_b_pending;

    // R handshake
    assign m_r_req = m_r_pending;
    assign m_r_ack = s_r_pending;

endmodule
