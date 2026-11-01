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
    reg [ADDR_WIDTH-1:0] s_awaddr_reg;
    reg [2:0]            s_awprot_reg;
    reg                  s_awvalid_reg;
    reg                  s_awready_reg;

    // S-side: capture AW when valid and ready
    wire s_aw_handshake = s_axil_awvalid & s_axil_awready;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_awaddr_reg  <= {ADDR_WIDTH{1'b0}};
            s_awprot_reg  <= 3'b000;
            s_awvalid_reg <= 1'b0;
            s_awready_reg <= 1'b0;
        end else begin
            if (s_aw_handshake) begin
                s_awaddr_reg  <= s_axil_awaddr;
                s_awprot_reg  <= s_axil_awprot;
                s_awvalid_reg <= 1'b1;
            end
            if (s_awready_reg) begin
                s_awvalid_reg <= 1'b0;
            end
        end
    end

    // M-side: output AW
    wire m_aw_handshake = m_axil_awvalid & m_axil_awready;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_awaddr  <= {ADDR_WIDTH{1'b0}};
            m_axil_awprot  <= 3'b000;
            m_axil_awvalid <= 1'b0;
        end else begin
            if (s_awvalid_reg && !m_axil_awvalid) begin
                m_axil_awaddr  <= s_awaddr_reg;
                m_axil_awprot  <= s_awprot_reg;
                m_axil_awvalid <= 1'b1;
            end
            if (m_aw_handshake) begin
                m_axil_awvalid <= 1'b0;
            end
        end
    end

    // S-side: AW ready
    assign s_axil_awready = s_awready_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_awready_reg <= 1'b0;
        end else begin
            if (m_aw_handshake) begin
                s_awready_reg <= 1'b1;
            end else if (s_aw_handshake) begin
                s_awready_reg <= 1'b0;
            end
        end
    end

    // ========================================================================
    // Write Data Channel: S -> M
    // ========================================================================
    reg [DATA_WIDTH-1:0] s_wdata_reg;
    reg [STRB_WIDTH-1:0] s_wstrb_reg;
    reg                  s_wvalid_reg;
    reg                  s_wready_reg;

    wire s_w_handshake = s_axil_wvalid & s_axil_wready;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wdata_reg  <= {DATA_WIDTH{1'b0}};
            s_wstrb_reg  <= {STRB_WIDTH{1'b0}};
            s_wvalid_reg <= 1'b0;
            s_wready_reg <= 1'b0;
        end else begin
            if (s_w_handshake) begin
                s_wdata_reg  <= s_axil_wdata;
                s_wstrb_reg  <= s_axil_wstrb;
                s_wvalid_reg <= 1'b1;
            end
            if (s_wready_reg) begin
                s_wvalid_reg <= 1'b0;
            end
        end
    end

    wire m_w_handshake = m_axil_wvalid & m_axil_wready;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_wdata  <= {DATA_WIDTH{1'b0}};
            m_axil_wstrb  <= {STRB_WIDTH{1'b0}};
            m_axil_wvalid <= 1'b0;
        end else begin
            if (s_wvalid_reg && !m_axil_wvalid) begin
                m_axil_wdata  <= s_wdata_reg;
                m_axil_wstrb  <= s_wstrb_reg;
                m_axil_wvalid <= 1'b1;
            end
            if (m_w_handshake) begin
                m_axil_wvalid <= 1'b0;
            end
        end
    end

    assign s_axil_wready = s_wready_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wready_reg <= 1'b0;
        end else begin
            if (m_w_handshake) begin
                s_wready_reg <= 1'b1;
            end else if (s_w_handshake) begin
                s_wready_reg <= 1'b0;
            end
        end
    end

    // ========================================================================
    // Write Response Channel: M -> S
    // ========================================================================
    reg [1:0] m_bresp_reg;
    reg       m_bvalid_reg;
    reg       m_bready_reg;

    wire m_b_handshake = m_axil_bvalid & m_axil_bready;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_bresp_reg  <= 2'b00;
            m_bvalid_reg <= 1'b0;
            m_bready_reg <= 1'b0;
        end else begin
            if (m_b_handshake) begin
                m_bresp_reg  <= m_axil_bresp;
                m_bvalid_reg <= 1'b1;
            end
            if (m_bready_reg) begin
                m_bvalid_reg <= 1'b0;
            end
        end
    end

    wire s_b_handshake = s_axil_bvalid & s_axil_bready;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axil_bresp  <= 2'b00;
            s_axil_bvalid <= 1'b0;
        end else begin
            if (m_bvalid_reg && !s_axil_bvalid) begin
                s_axil_bresp  <= m_bresp_reg;
                s_axil_bvalid <= 1'b1;
            end
            if (s_b_handshake) begin
                s_axil_bvalid <= 1'b0;
            end
        end
    end

    assign m_axil_bready = m_bready_reg;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_bready_reg <= 1'b0;
        end else begin
            if (s_b_handshake) begin
                m_bready_reg <= 1'b1;
            end else if (m_b_handshake) begin
                m_bready_reg <= 1'b0;
            end
        end
    end

    // ========================================================================
    // Read Address Channel: S -> M
    // ========================================================================
    reg [ADDR_WIDTH-1:0] s_araddr_reg;
    reg [2:0]            s_arprot_reg;
    reg                  s_arvalid_reg;
    reg                  s_arready_reg;

    wire s_ar_handshake = s_axil_arvalid & s_axil_arready;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_araddr_reg  <= {ADDR_WIDTH{1'b0}};
            s_arprot_reg  <= 3'b000;
            s_arvalid_reg <= 1'b0;
            s_arready_reg <= 1'b0;
        end else begin
            if (s_ar_handshake) begin
                s_araddr_reg  <= s_axil_araddr;
                s_arprot_reg  <= s_axil_arprot;
                s_arvalid_reg <= 1'b1;
            end
            if (s_arready_reg) begin
                s_arvalid_reg <= 1'b0;
            end
        end
    end

    wire m_ar_handshake = m_axil_arvalid & m_axil_arready;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_araddr  <= {ADDR_WIDTH{1'b0}};
            m_axil_arprot  <= 3'b000;
            m_axil_arvalid <= 1'b0;
        end else begin
            if (s_arvalid_reg && !m_axil_arvalid) begin
                m_axil_araddr  <= s_araddr_reg;
                m_axil_arprot  <= s_arprot_reg;
                m_axil_arvalid <= 1'b1;
            end
            if (m_ar_handshake) begin
                m_axil_arvalid <= 1'b0;
            end
        end
    end

    assign s_axil_arready = s_arready_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_arready_reg <= 1'b0;
        end else begin
            if (m_ar_handshake) begin
                s_arready_reg <= 1'b1;
            end else if (s_ar_handshake) begin
                s_arready_reg <= 1'b0;
            end
        end
    end

    // ========================================================================
    // Read Data Channel: M -> S
    // ========================================================================
    reg [DATA_WIDTH-1:0] m_rdata_reg;
    reg [1:0]            m_rresp_reg;
    reg                  m_rvalid_reg;
    reg                  m_rready_reg;

    wire m_r_handshake = m_axil_rvalid & m_axil_rready;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rdata_reg  <= {DATA_WIDTH{1'b0}};
            m_rresp_reg  <= 2'b00;
            m_rvalid_reg <= 1'b0;
            m_rready_reg <= 1'b0;
        end else begin
            if (m_r_handshake) begin
                m_rdata_reg  <= m_axil_rdata;
                m_rresp_reg  <= m_axil_rresp;
                m_rvalid_reg <= 1'b1;
            end
            if (m_rready_reg) begin
                m_rvalid_reg <= 1'b0;
            end
        end
    end

    wire s_r_handshake = s_axil_rvalid & s_axil_rready;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axil_rdata  <= {DATA_WIDTH{1'b0}};
            s_axil_rresp  <= 2'b00;
            s_axil_rvalid <= 1'b0;
        end else begin
            if (m_rvalid_reg && !s_axil_rvalid) begin
                s_axil_rdata  <= m_rdata_reg;
                s_axil_rresp  <= m_rresp_reg;
                s_axil_rvalid <= 1'b1;
            end
            if (s_r_handshake) begin
                s_axil_rvalid <= 1'b0;
            end
        end
    end

    assign m_axil_rready = m_rready_reg;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rready_reg <= 1'b0;
        end else begin
            if (s_r_handshake) begin
                m_rready_reg <= 1'b1;
            end else if (m_r_handshake) begin
                m_rready_reg <= 1'b0;
            end
        end
    end

endmodule
