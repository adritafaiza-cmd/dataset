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

    wire s_aw_handshake = s_axil_awvalid & s_axil_awready;

    assign s_axil_awready = s_awready_reg;

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
            end else if (s_awvalid_reg & s_awready_reg) begin
                s_awvalid_reg <= 1'b0;
            end
        end
    end

    // AW CDC: s -> m
    wire [ADDR_WIDTH+3:0] aw_cdc_data = {s_awvalid_reg, s_awprot_reg, s_awaddr_reg};
    wire [ADDR_WIDTH+3:0] aw_cdc_data_m;
    wire [ADDR_WIDTH+3:0] aw_cdc_data_m2;

    // Simple 2-flop synchronizer for each bit is not enough for multi-bit.
    // Use a handshake-based CDC for the AW channel.
    // We'll use a simple request/acknowledge scheme.

    reg  s_aw_req;
    reg  m_aw_ack;
    reg  m_aw_ack_s;
    reg  m_aw_ack_s2;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_aw_req <= 1'b0;
        end else begin
            if (s_awvalid_reg & ~m_aw_ack_s2) begin
                s_aw_req <= 1'b1;
            end else if (m_aw_ack_s2) begin
                s_aw_req <= 1'b0;
            end
        end
    end

    // Synchronize m_aw_ack to s domain
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_aw_ack_s  <= 1'b0;
            m_aw_ack_s2 <= 1'b0;
        end else begin
            m_aw_ack_s  <= m_aw_ack;
            m_aw_ack_s2 <= m_aw_ack_s;
        end
    end

    // Synchronize s_aw_req to m domain
    reg s_aw_req_m;
    reg s_aw_req_m2;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_aw_req_m  <= 1'b0;
            s_aw_req_m2 <= 1'b0;
        end else begin
            s_aw_req_m  <= s_aw_req;
            s_aw_req_m2 <= s_aw_req_m;
        end
    end

    // In m domain, when s_aw_req_m2 is high, capture the data and assert ack
    reg [ADDR_WIDTH-1:0] m_awaddr_reg;
    reg [2:0]            m_awprot_reg;
    reg                  m_awvalid_reg;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_aw_ack      <= 1'b0;
            m_awaddr_reg  <= {ADDR_WIDTH{1'b0}};
            m_awprot_reg  <= 3'b000;
            m_awvalid_reg <= 1'b0;
        end else begin
            if (s_aw_req_m2 & ~m_aw_ack) begin
                // Capture data from s domain (stable while s_aw_req is high)
                m_awaddr_reg  <= s_awaddr_reg;
                m_awprot_reg  <= s_awprot_reg;
                m_awvalid_reg <= 1'b1;
                m_aw_ack      <= 1'b1;
            end else if (m_awvalid_reg & m_axil_awready) begin
                m_awvalid_reg <= 1'b0;
                m_aw_ack      <= 1'b0;
            end
        end
    end

    assign m_axil_awaddr  = m_awaddr_reg;
    assign m_axil_awprot  = m_awprot_reg;
    assign m_axil_awvalid = m_awvalid_reg;

    // ========================================================================
    // Write Data Channel (W) - Slave to Master
    // ========================================================================
    reg [DATA_WIDTH-1:0] s_wdata_reg;
    reg [STRB_WIDTH-1:0] s_wstrb_reg;
    reg                  s_wvalid_reg;
    reg                  s_wready_reg;

    wire s_w_handshake = s_axil_wvalid & s_axil_wready;

    assign s_axil_wready = s_wready_reg;

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
            end else if (s_wvalid_reg & s_wready_reg) begin
                s_wvalid_reg <= 1'b0;
            end
        end
    end

    // W CDC: s -> m
    reg  s_w_req;
    reg  m_w_ack;
    reg  m_w_ack_s;
    reg  m_w_ack_s2;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_w_req <= 1'b0;
        end else begin
            if (s_wvalid_reg & ~m_w_ack_s2) begin
                s_w_req <= 1'b1;
            end else if (m_w_ack_s2) begin
                s_w_req <= 1'b0;
            end
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_w_ack_s  <= 1'b0;
            m_w_ack_s2 <= 1'b0;
        end else begin
            m_w_ack_s  <= m_w_ack;
            m_w_ack_s2 <= m_w_ack_s;
        end
    end

    reg s_w_req_m;
    reg s_w_req_m2;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_w_req_m  <= 1'b0;
            s_w_req_m2 <= 1'b0;
        end else begin
            s_w_req_m  <= s_w_req;
            s_w_req_m2 <= s_w_req_m;
        end
    end

    reg [DATA_WIDTH-1:0] m_wdata_reg;
    reg [STRB_WIDTH-1:0] m_wstrb_reg;
    reg                  m_wvalid_reg;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_w_ack      <= 1'b0;
            m_wdata_reg  <= {DATA_WIDTH{1'b0}};
            m_wstrb_reg  <= {STRB_WIDTH{1'b0}};
            m_wvalid_reg <= 1'b0;
        end else begin
            if (s_w_req_m2 & ~m_w_ack) begin
                m_wdata_reg  <= s_wdata_reg;
                m_wstrb_reg  <= s_wstrb_reg;
                m_wvalid_reg <= 1'b1;
                m_w_ack      <= 1'b1;
            end else if (m_wvalid_reg & m_axil_wready) begin
                m_wvalid_reg <= 1'b0;
                m_w_ack      <= 1'b0;
            end
        end
    end

    assign m_axil_wdata  = m_wdata_reg;
    assign m_axil_wstrb  = m_wstrb_reg;
    assign m_axil_wvalid = m_wvalid_reg;

    // ========================================================================
    // Write Response Channel (B) - Master to Slave
    // ========================================================================
    reg [1:0] m_bresp_reg;
    reg       m_bvalid_reg;
    reg       m_bready_reg;

    wire m_b_handshake = m_axil_bvalid & m_axil_bready;

    assign m_axil_bready = m_bready_reg;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_bresp_reg  <= 2'b00;
            m_bvalid_reg <= 1'b0;
            m_bready_reg <= 1'b0;
        end else begin
            if (m_b_handshake) begin
                m_bresp_reg  <= m_axil_bresp;
                m_bvalid_reg <= 1'b1;
            end else if (m_bvalid_reg & m_bready_reg) begin
                m_bvalid_reg <= 1'b0;
            end
        end
    end

    // B CDC: m -> s
    reg  m_b_req;
    reg  s_b_ack;
    reg  s_b_ack_m;
    reg  s_b_ack_m2;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_b_req <= 1'b0;
        end else begin
            if (m_bvalid_reg & ~s_b_ack_m2) begin
                m_b_req <= 1'b1;
            end else if (s_b_ack_m2) begin
                m_b_req <= 1'b0;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_b_ack_m  <= 1'b0;
            s_b_ack_m2 <= 1'b0;
        end else begin
            s_b_ack_m  <= s_b_ack;
            s_b_ack_m2 <= s_b_ack_m;
        end
    end

    reg m_b_req_s;
    reg m_b_req_s2;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_b_req_s  <= 1'b0;
            m_b_req_s2 <= 1'b0;
        end else begin
            m_b_req_s  <= m_b_req;
            m_b_req_s2 <= m_b_req_s;
        end
    end

    reg [1:0] s_bresp_reg;
    reg       s_bvalid_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_b_ack      <= 1'b0;
            s_bresp_reg  <= 2'b00;
            s_bvalid_reg <= 1'b0;
        end else begin
            if (m_b_req_s2 & ~s_b_ack) begin
                s_bresp_reg  <= m_bresp_reg;
                s_bvalid_reg <= 1'b1;
                s_b_ack      <= 1'b1;
            end else if (s_bvalid_reg & s_axil_bready) begin
                s_bvalid_reg <= 1'b0;
                s_b_ack      <= 1'b0;
            end
        end
    end

    assign s_axil_bresp  = s_bresp_reg;
    assign s_axil_bvalid = s_bvalid_reg;

    // ========================================================================
    // Read Address Channel (AR) - Slave to Master
    // ========================================================================
    reg [ADDR_WIDTH-1:0] s_araddr_reg;
    reg [2:0]            s_arprot_reg;
    reg                  s_arvalid_reg;
    reg                  s_arready_reg;

    wire s_ar_handshake = s_axil_arvalid & s_axil_arready;

    assign s_axil_arready = s_arready_reg;

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
            end else if (s_arvalid_reg & s_arready_reg) begin
                s_arvalid_reg <= 1'b0;
            end
        end
    end

    // AR CDC: s -> m
    reg  s_ar_req;
    reg  m_ar_ack;
    reg  m_ar_ack_s;
    reg  m_ar_ack_s2;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_ar_req <= 1'b0;
        end else begin
            if (s_arvalid_reg & ~m_ar_ack_s2) begin
                s_ar_req <= 1'b1;
            end else if (m_ar_ack_s2) begin
                s_ar_req <= 1'b0;
            end
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_ar_ack_s  <= 1'b0;
            m_ar_ack_s2 <= 1'b0;
        end else begin
            m_ar_ack_s  <= m_ar_ack;
            m_ar_ack_s2 <= m_ar_ack_s;
        end
    end

    reg s_ar_req_m;
    reg s_ar_req_m2;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_ar_req_m  <= 1'b0;
            s_ar_req_m2 <= 1'b0;
        end else begin
            s_ar_req_m  <= s_ar_req;
            s_ar_req_m2 <= s_ar_req_m;
        end
    end

    reg [ADDR_WIDTH-1:0] m_araddr_reg;
    reg [2:0]            m_arprot_reg;
    reg                  m_arvalid_reg;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_ar_ack      <= 1'b0;
            m_araddr_reg  <= {ADDR_WIDTH{1'b0}};
            m_arprot_reg  <= 3'b000;
            m_arvalid_reg <= 1'b0;
        end else begin
            if (s_ar_req_m2 & ~m_ar_ack) begin
                m_araddr_reg  <= s_araddr_reg;
                m_arprot_reg  <= s_arprot_reg;
                m_arvalid_reg <= 1'b1;
                m_ar_ack      <= 1'b1;
            end else if (m_arvalid_reg & m_axil_arready) begin
                m_arvalid_reg <= 1'b0;
                m_ar_ack      <= 1'b0;
            end
        end
    end

    assign m_axil_araddr  = m_araddr_reg;
    assign m_axil_arprot  = m_arprot_reg;
    assign m_axil_arvalid = m_arvalid_reg;

    // ========================================================================
    // Read Data Channel (R) - Master to Slave
    // ========================================================================
    reg [DATA_WIDTH-1:0] m_rdata_reg;
    reg [1:0]            m_rresp_reg;
    reg                  m_rvalid_reg;
    reg                  m_rready_reg;

    wire m_r_handshake = m_axil_rvalid & m_axil_rready;

    assign m_axil_rready = m_rready_reg;

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
            end else if (m_rvalid_reg & m_rready_reg) begin
                m_rvalid_reg <= 1'b0;
            end
        end
    end

    // R CDC: m -> s
    reg  m_r_req;
    reg  s_r_ack;
    reg  s_r_ack_m;
    reg  s_r_ack_m2;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_r_req <= 1'b0;
        end else begin
            if (m_rvalid_reg & ~s_r_ack_m2) begin
                m_r_req <= 1'b1;
            end else if (s_r_ack_m2) begin
                m_r_req <= 1'b0;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_r_ack_m  <= 1'b0;
            s_r_ack_m2 <= 1'b0;
        end else begin
            s_r_ack_m  <= s_r_ack;
            s_r_ack_m2 <= s_r_ack_m;
        end
    end

    reg m_r_req_s;
    reg m_r_req_s2;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_r_req_s  <= 1'b0;
            m_r_req_s2 <= 1'b0;
        end else begin
            m_r_req_s  <= m_r_req;
            m_r_req_s2 <= m_r_req_s;
        end
    end

    reg [DATA_WIDTH-1:0] s_rdata_reg;
    reg [1:0]            s_rresp_reg;
    reg                  s_rvalid_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_r_ack      <= 1'b0;
            s_rdata_reg  <= {DATA_WIDTH{1'b0}};
            s_rresp_reg  <= 2'b00;
            s_rvalid_reg <= 1'b0;
        end else begin
            if (m_r_req_s2 & ~s_r_ack) begin
                s_rdata_reg  <= m_rdata_reg;
                s_rresp_reg  <= m_rresp_reg;
                s_rvalid_reg <= 1'b1;
                s_r_ack      <= 1'b1;
            end else if (s_rvalid_reg & s_axil_rready) begin
                s_rvalid_reg <= 1'b0;
                s_r_ack      <= 1'b0;
            end
        end
    end

    assign s_axil_rdata  = s_rdata_reg;
    assign s_axil_rresp  = s_rresp_reg;
    assign s_axil_rvalid = s_rvalid_reg;

endmodule
