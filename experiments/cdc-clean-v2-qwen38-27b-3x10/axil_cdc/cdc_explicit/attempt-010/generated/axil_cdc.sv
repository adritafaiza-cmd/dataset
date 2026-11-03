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
    // Write Address Channel (AW): S -> M
    // ========================================================================
    reg  [ADDR_WIDTH-1:0] s_awaddr_reg;
    reg  [2:0]            s_awprot_reg;
    reg                   s_aw_req;
    wire                  m_aw_ack;

    // Synchronizer for request
    reg [2:0] s_aw_req_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            s_aw_req_sync <= 3'b000;
        else
            s_aw_req_sync <= {s_aw_req_sync[1:0], s_aw_req};
    end
    wire m_aw_req = s_aw_req_sync[2];

    // Synchronizer for acknowledge
    reg [2:0] m_aw_ack_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            m_aw_ack_sync <= 3'b000;
        else
            m_aw_ack_sync <= {m_aw_ack_sync[1:0], m_aw_ack};
    end
    wire s_aw_ack = m_aw_ack_sync[2];

    // S-side AW state machine
    reg s_aw_pending;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_aw_pending <= 1'b0;
        else if (s_axil_awvalid && s_axil_awready)
            s_aw_pending <= 1'b1;
        else if (s_aw_ack)
            s_aw_pending <= 1'b0;
    end

    assign s_axil_awready = ~s_aw_pending;

    // Capture AW payload on S side
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_awaddr_reg <= {ADDR_WIDTH{1'b0}};
            s_awprot_reg <= 3'b000;
            s_aw_req     <= 1'b0;
        end
        else if (s_axil_awvalid && s_axil_awready) begin
            s_awaddr_reg <= s_axil_awaddr;
            s_awprot_reg <= s_axil_awprot;
            s_aw_req     <= 1'b1;
        end
        else if (s_aw_ack) begin
            s_aw_req <= 1'b0;
        end
    end

    // M-side AW state machine
    reg m_aw_pending;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_aw_pending <= 1'b0;
        else if (m_aw_req && !m_aw_pending)
            m_aw_pending <= 1'b1;
        else if (m_axil_awvalid && m_axil_awready)
            m_aw_pending <= 1'b0;
    end

    assign m_axil_awvalid = m_aw_pending;
    assign m_axil_awaddr  = s_awaddr_reg;
    assign m_axil_awprot  = s_awprot_reg;
    assign m_aw_ack       = m_axil_awvalid && m_axil_awready;

    // ========================================================================
    // Write Data Channel (W): S -> M
    // ========================================================================
    reg  [DATA_WIDTH-1:0] s_wdata_reg;
    reg  [STRB_WIDTH-1:0] s_wstrb_reg;
    reg                   s_w_req;
    wire                  m_w_ack;

    // Synchronizer for request
    reg [2:0] s_w_req_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            s_w_req_sync <= 3'b000;
        else
            s_w_req_sync <= {s_w_req_sync[1:0], s_w_req};
    end
    wire m_w_req = s_w_req_sync[2];

    // Synchronizer for acknowledge
    reg [2:0] m_w_ack_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            m_w_ack_sync <= 3'b000;
        else
            m_w_ack_sync <= {m_w_ack_sync[1:0], m_w_ack};
    end
    wire s_w_ack = m_w_ack_sync[2];

    // S-side W state machine
    reg s_w_pending;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_w_pending <= 1'b0;
        else if (s_axil_wvalid && s_axil_wready)
            s_w_pending <= 1'b1;
        else if (s_w_ack)
            s_w_pending <= 1'b0;
    end

    assign s_axil_wready = ~s_w_pending;

    // Capture W payload on S side
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wdata_reg <= {DATA_WIDTH{1'b0}};
            s_wstrb_reg <= {STRB_WIDTH{1'b0}};
            s_w_req     <= 1'b0;
        end
        else if (s_axil_wvalid && s_axil_wready) begin
            s_wdata_reg <= s_axil_wdata;
            s_wstrb_reg <= s_axil_wstrb;
            s_w_req     <= 1'b1;
        end
        else if (s_w_ack) begin
            s_w_req <= 1'b0;
        end
    end

    // M-side W state machine
    reg m_w_pending;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_w_pending <= 1'b0;
        else if (m_w_req && !m_w_pending)
            m_w_pending <= 1'b1;
        else if (m_axil_wvalid && m_axil_wready)
            m_w_pending <= 1'b0;
    end

    assign m_axil_wvalid = m_w_pending;
    assign m_axil_wdata  = s_wdata_reg;
    assign m_axil_wstrb  = s_wstrb_reg;
    assign m_w_ack       = m_axil_wvalid && m_axil_wready;

    // ========================================================================
    // Write Response Channel (B): M -> S
    // ========================================================================
    reg  [1:0] m_bresp_reg;
    reg        m_b_req;
    wire       s_b_ack;

    // Synchronizer for request
    reg [2:0] m_b_req_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            m_b_req_sync <= 3'b000;
        else
            m_b_req_sync <= {m_b_req_sync[1:0], m_b_req};
    end
    wire s_b_req = m_b_req_sync[2];

    // Synchronizer for acknowledge
    reg [2:0] s_b_ack_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            s_b_ack_sync <= 3'b000;
        else
            s_b_ack_sync <= {s_b_ack_sync[1:0], s_b_ack};
    end
    wire m_b_ack = s_b_ack_sync[2];

    // M-side B state machine
    reg m_b_pending;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_b_pending <= 1'b0;
        else if (m_axil_bvalid && m_axil_bready)
            m_b_pending <= 1'b1;
        else if (m_b_ack)
            m_b_pending <= 1'b0;
    end

    assign m_axil_bready = ~m_b_pending;

    // Capture B payload on M side
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_bresp_reg <= 2'b00;
            m_b_req     <= 1'b0;
        end
        else if (m_axil_bvalid && m_axil_bready) begin
            m_bresp_reg <= m_axil_bresp;
            m_b_req     <= 1'b1;
        end
        else if (m_b_ack) begin
            m_b_req <= 1'b0;
        end
    end

    // S-side B state machine
    reg s_b_pending;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_b_pending <= 1'b0;
        else if (s_b_req && !s_b_pending)
            s_b_pending <= 1'b1;
        else if (s_axil_bvalid && s_axil_bready)
            s_b_pending <= 1'b0;
    end

    assign s_axil_bvalid = s_b_pending;
    assign s_axil_bresp  = m_bresp_reg;
    assign s_b_ack       = s_axil_bvalid && s_axil_bready;

    // ========================================================================
    // Read Address Channel (AR): S -> M
    // ========================================================================
    reg  [ADDR_WIDTH-1:0] s_araddr_reg;
    reg  [2:0]            s_arprot_reg;
    reg                   s_ar_req;
    wire                  m_ar_ack;

    // Synchronizer for request
    reg [2:0] s_ar_req_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            s_ar_req_sync <= 3'b000;
        else
            s_ar_req_sync <= {s_ar_req_sync[1:0], s_ar_req};
    end
    wire m_ar_req = s_ar_req_sync[2];

    // Synchronizer for acknowledge
    reg [2:0] m_ar_ack_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            m_ar_ack_sync <= 3'b000;
        else
            m_ar_ack_sync <= {m_ar_ack_sync[1:0], m_ar_ack};
    end
    wire s_ar_ack = m_ar_ack_sync[2];

    // S-side AR state machine
    reg s_ar_pending;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_ar_pending <= 1'b0;
        else if (s_axil_arvalid && s_axil_arready)
            s_ar_pending <= 1'b1;
        else if (s_ar_ack)
            s_ar_pending <= 1'b0;
    end

    assign s_axil_arready = ~s_ar_pending;

    // Capture AR payload on S side
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_araddr_reg <= {ADDR_WIDTH{1'b0}};
            s_arprot_reg <= 3'b000;
            s_ar_req     <= 1'b0;
        end
        else if (s_axil_arvalid && s_axil_arready) begin
            s_araddr_reg <= s_axil_araddr;
            s_arprot_reg <= s_axil_arprot;
            s_ar_req     <= 1'b1;
        end
        else if (s_ar_ack) begin
            s_ar_req <= 1'b0;
        end
    end

    // M-side AR state machine
    reg m_ar_pending;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_ar_pending <= 1'b0;
        else if (m_ar_req && !m_ar_pending)
            m_ar_pending <= 1'b1;
        else if (m_axil_arvalid && m_axil_arready)
            m_ar_pending <= 1'b0;
    end

    assign m_axil_arvalid = m_ar_pending;
    assign m_axil_araddr  = s_araddr_reg;
    assign m_axil_arprot  = s_arprot_reg;
    assign m_ar_ack       = m_axil_arvalid && m_axil_arready;

    // ========================================================================
    // Read Data Channel (R): M -> S
    // ========================================================================
    reg  [DATA_WIDTH-1:0] m_rdata_reg;
    reg  [1:0]            m_rresp_reg;
    reg                   m_r_req;
    wire                  s_r_ack;

    // Synchronizer for request
    reg [2:0] m_r_req_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            m_r_req_sync <= 3'b000;
        else
            m_r_req_sync <= {m_r_req_sync[1:0], m_r_req};
    end
    wire s_r_req = m_r_req_sync[2];

    // Synchronizer for acknowledge
    reg [2:0] s_r_ack_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            s_r_ack_sync <= 3'b000;
        else
            s_r_ack_sync <= {s_r_ack_sync[1:0], s_r_ack};
    end
    wire m_r_ack = s_r_ack_sync[2];

    // M-side R state machine
    reg m_r_pending;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_r_pending <= 1'b0;
        else if (m_axil_rvalid && m_axil_rready)
            m_r_pending <= 1'b1;
        else if (m_r_ack)
            m_r_pending <= 1'b0;
    end

    assign m_axil_rready = ~m_r_pending;

    // Capture R payload on M side
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rdata_reg <= {DATA_WIDTH{1'b0}};
            m_rresp_reg <= 2'b00;
            m_r_req     <= 1'b0;
        end
        else if (m_axil_rvalid && m_axil_rready) begin
            m_rdata_reg <= m_axil_rdata;
            m_rresp_reg <= m_axil_rresp;
            m_r_req     <= 1'b1;
        end
        else if (m_r_ack) begin
            m_r_req <= 1'b0;
        end
    end

    // S-side R state machine
    reg s_r_pending;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_r_pending <= 1'b0;
        else if (s_r_req && !s_r_pending)
            s_r_pending <= 1'b1;
        else if (s_axil_rvalid && s_axil_rready)
            s_r_pending <= 1'b0;
    end

    assign s_axil_rvalid = s_r_pending;
    assign s_axil_rdata  = m_rdata_reg;
    assign s_axil_rresp  = m_rresp_reg;
    assign s_r_ack       = s_axil_rvalid && s_axil_rready;

endmodule
