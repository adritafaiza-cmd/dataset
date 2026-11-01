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

    // Synchronous reset for s domain
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
            if (s_awvalid_reg & s_awready_reg) begin
                s_awvalid_reg <= 1'b0;
            end
        end
    end

    // CDC: s_awvalid_reg (S) -> M
    wire [1:0] s_awvalid_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            s_awvalid_sync <= 2'b00;
        else
            s_awvalid_sync <= {s_awvalid_sync[0], s_awvalid_reg};
    end

    // CDC: m_awready (M) -> S
    wire [1:0] m_awready_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            m_awready_sync <= 2'b00;
        else
            m_awready_sync <= {m_awready_sync[0], m_axil_awready};
    end

    // M domain: AW channel
    reg [ADDR_WIDTH-1:0] m_awaddr_reg;
    reg [2:0]            m_awprot_reg;
    reg                  m_awvalid_reg;
    reg                  m_awready_reg;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_awaddr_reg  <= {ADDR_WIDTH{1'b0}};
            m_awprot_reg  <= 3'b000;
            m_awvalid_reg <= 1'b0;
            m_awready_reg <= 1'b0;
        end else begin
            if (s_awvalid_sync[1] & ~m_awvalid_reg) begin
                m_awaddr_reg  <= s_awaddr_reg;
                m_awprot_reg  <= s_awprot_reg;
                m_awvalid_reg <= 1'b1;
            end
            if (m_awvalid_reg & m_axil_awready) begin
                m_awvalid_reg <= 1'b0;
            end
            m_awready_reg <= m_axil_awready;
        end
    end

    assign s_axil_awready = m_awready_sync[1];
    assign m_axil_awaddr  = m_awaddr_reg;
    assign m_axil_awprot  = m_awprot_reg;
    assign m_axil_awvalid = m_awvalid_reg;

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
            if (s_wvalid_reg & s_wready_reg) begin
                s_wvalid_reg <= 1'b0;
            end
        end
    end

    // CDC: s_wvalid_reg (S) -> M
    wire [1:0] s_wvalid_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            s_wvalid_sync <= 2'b00;
        else
            s_wvalid_sync <= {s_wvalid_sync[0], s_wvalid_reg};
    end

    // CDC: m_wready (M) -> S
    wire [1:0] m_wready_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            m_wready_sync <= 2'b00;
        else
            m_wready_sync <= {m_wready_sync[0], m_axil_wready};
    end

    // M domain: W channel
    reg [DATA_WIDTH-1:0] m_wdata_reg;
    reg [STRB_WIDTH-1:0] m_wstrb_reg;
    reg                  m_wvalid_reg;
    reg                  m_wready_reg;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_wdata_reg  <= {DATA_WIDTH{1'b0}};
            m_wstrb_reg  <= {STRB_WIDTH{1'b0}};
            m_wvalid_reg <= 1'b0;
            m_wready_reg <= 1'b0;
        end else begin
            if (s_wvalid_sync[1] & ~m_wvalid_reg) begin
                m_wdata_reg  <= s_wdata_reg;
                m_wstrb_reg  <= s_wstrb_reg;
                m_wvalid_reg <= 1'b1;
            end
            if (m_wvalid_reg & m_axil_wready) begin
                m_wvalid_reg <= 1'b0;
            end
            m_wready_reg <= m_axil_wready;
        end
    end

    assign s_axil_wready = m_wready_sync[1];
    assign m_axil_wdata  = m_wdata_reg;
    assign m_axil_wstrb  = m_wstrb_reg;
    assign m_axil_wvalid = m_wvalid_reg;

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
            if (m_bvalid_reg & m_bready_reg) begin
                m_bvalid_reg <= 1'b0;
            end
        end
    end

    // CDC: m_bvalid_reg (M) -> S
    wire [1:0] m_bvalid_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            m_bvalid_sync <= 2'b00;
        else
            m_bvalid_sync <= {m_bvalid_sync[0], m_bvalid_reg};
    end

    // CDC: s_bready (S) -> M
    wire [1:0] s_bready_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            s_bready_sync <= 2'b00;
        else
            s_bready_sync <= {s_bready_sync[0], s_axil_bready};
    end

    // S domain: B channel
    reg [1:0] s_bresp_reg;
    reg       s_bvalid_reg;
    reg       s_bready_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_bresp_reg  <= 2'b00;
            s_bvalid_reg <= 1'b0;
            s_bready_reg <= 1'b0;
        end else begin
            if (m_bvalid_sync[1] & ~s_bvalid_reg) begin
                s_bresp_reg  <= m_bresp_reg;
                s_bvalid_reg <= 1'b1;
            end
            if (s_bvalid_reg & s_axil_bready) begin
                s_bvalid_reg <= 1'b0;
            end
            s_bready_reg <= s_axil_bready;
        end
    end

    assign s_axil_bresp  = s_bresp_reg;
    assign s_axil_bvalid = s_bvalid_reg;
    assign m_axil_bready = s_bready_sync[1];

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
            if (s_arvalid_reg & s_arready_reg) begin
                s_arvalid_reg <= 1'b0;
            end
        end
    end

    // CDC: s_arvalid_reg (S) -> M
    wire [1:0] s_arvalid_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            s_arvalid_sync <= 2'b00;
        else
            s_arvalid_sync <= {s_arvalid_sync[0], s_arvalid_reg};
    end

    // CDC: m_arready (M) -> S
    wire [1:0] m_arready_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            m_arready_sync <= 2'b00;
        else
            m_arready_sync <= {m_arready_sync[0], m_axil_arready};
    end

    // M domain: AR channel
    reg [ADDR_WIDTH-1:0] m_araddr_reg;
    reg [2:0]            m_arprot_reg;
    reg                  m_arvalid_reg;
    reg                  m_arready_reg;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_araddr_reg  <= {ADDR_WIDTH{1'b0}};
            m_arprot_reg  <= 3'b000;
            m_arvalid_reg <= 1'b0;
            m_arready_reg <= 1'b0;
        end else begin
            if (s_arvalid_sync[1] & ~m_arvalid_reg) begin
                m_araddr_reg  <= s_araddr_reg;
                m_arprot_reg  <= s_arprot_reg;
                m_arvalid_reg <= 1'b1;
            end
            if (m_arvalid_reg & m_axil_arready) begin
                m_arvalid_reg <= 1'b0;
            end
            m_arready_reg <= m_axil_arready;
        end
    end

    assign s_axil_arready = m_arready_sync[1];
    assign m_axil_araddr  = m_araddr_reg;
    assign m_axil_arprot  = m_arprot_reg;
    assign m_axil_arvalid = m_arvalid_reg;

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
            if (m_rvalid_reg & m_rready_reg) begin
                m_rvalid_reg <= 1'b0;
            end
        end
    end

    // CDC: m_rvalid_reg (M) -> S
    wire [1:0] m_rvalid_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            m_rvalid_sync <= 2'b00;
        else
            m_rvalid_sync <= {m_rvalid_sync[0], m_rvalid_reg};
    end

    // CDC: s_rready (S) -> M
    wire [1:0] s_rready_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            s_rready_sync <= 2'b00;
        else
            s_rready_sync <= {s_rready_sync[0], s_axil_rready};
    end

    // S domain: R channel
    reg [DATA_WIDTH-1:0] s_rdata_reg;
    reg [1:0]            s_rresp_reg;
    reg                  s_rvalid_reg;
    reg                  s_rready_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_rdata_reg  <= {DATA_WIDTH{1'b0}};
            s_rresp_reg  <= 2'b00;
            s_rvalid_reg <= 1'b0;
            s_rready_reg <= 1'b0;
        end else begin
            if (m_rvalid_sync[1] & ~s_rvalid_reg) begin
                s_rdata_reg  <= m_rdata_reg;
                s_rresp_reg  <= m_rresp_reg;
                s_rvalid_reg <= 1'b1;
            end
            if (s_rvalid_reg & s_axil_rready) begin
                s_rvalid_reg <= 1'b0;
            end
            s_rready_reg <= s_axil_rready;
        end
    end

    assign s_axil_rdata  = s_rdata_reg;
    assign s_axil_rresp  = s_rresp_reg;
    assign s_axil_rvalid = s_rvalid_reg;
    assign m_axil_rready = s_rready_sync[1];

endmodule
