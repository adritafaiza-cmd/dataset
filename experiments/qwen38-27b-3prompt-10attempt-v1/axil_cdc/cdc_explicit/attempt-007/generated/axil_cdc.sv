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
            end else if (s_awready_reg) begin
                s_awvalid_reg <= 1'b0;
            end
            s_awready_reg <= m_axil_awready;
        end
    end

    assign s_axil_awready = s_awready_reg;
    assign m_axil_awaddr  = s_awaddr_reg;
    assign m_axil_awprot  = s_awprot_reg;
    assign m_axil_awvalid = s_awvalid_reg;

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
            end else if (s_wready_reg) begin
                s_wvalid_reg <= 1'b0;
            end
            s_wready_reg <= m_axil_wready;
        end
    end

    assign s_axil_wready = s_wready_reg;
    assign m_axil_wdata  = s_wdata_reg;
    assign m_axil_wstrb  = s_wstrb_reg;
    assign m_axil_wvalid = s_wvalid_reg;

    // ========================================================================
    // Write Response Channel: M -> S
    // ========================================================================
    reg [1:0] s_bresp_reg;
    reg       s_bvalid_reg;
    reg       s_bready_reg;

    wire m_b_handshake = m_axil_bvalid & m_axil_bready;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_bresp_reg  <= 2'b00;
            s_bvalid_reg <= 1'b0;
            s_bready_reg <= 1'b0;
        end else begin
            if (m_b_handshake) begin
                s_bresp_reg  <= m_axil_bresp;
                s_bvalid_reg <= 1'b1;
            end else if (s_bready_reg) begin
                s_bvalid_reg <= 1'b0;
            end
            s_bready_reg <= s_axil_bready;
        end
    end

    assign m_axil_bready = s_bready_reg;
    assign s_axil_bresp  = s_bresp_reg;
    assign s_axil_bvalid = s_bvalid_reg;

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
            end else if (s_arready_reg) begin
                s_arvalid_reg <= 1'b0;
            end
            s_arready_reg <= m_axil_arready;
        end
    end

    assign s_axil_arready = s_arready_reg;
    assign m_axil_araddr  = s_araddr_reg;
    assign m_axil_arprot  = s_arprot_reg;
    assign m_axil_arvalid = s_arvalid_reg;

    // ========================================================================
    // Read Data Channel: M -> S
    // ========================================================================
    reg [DATA_WIDTH-1:0] s_rdata_reg;
    reg [1:0]            s_rresp_reg;
    reg                  s_rvalid_reg;
    reg                  s_rready_reg;

    wire m_r_handshake = m_axil_rvalid & m_axil_rready;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_rdata_reg  <= {DATA_WIDTH{1'b0}};
            s_rresp_reg  <= 2'b00;
            s_rvalid_reg <= 1'b0;
            s_rready_reg <= 1'b0;
        end else begin
            if (m_r_handshake) begin
                s_rdata_reg  <= m_axil_rdata;
                s_rresp_reg  <= m_axil_rresp;
                s_rvalid_reg <= 1'b1;
            end else if (s_rready_reg) begin
                s_rvalid_reg <= 1'b0;
            end
            s_rready_reg <= s_axil_rready;
        end
    end

    assign m_axil_rready = s_rready_reg;
    assign s_axil_rdata  = s_rdata_reg;
    assign s_axil_rresp  = s_rresp_reg;
    assign s_axil_rvalid = s_rvalid_reg;

endmodule
