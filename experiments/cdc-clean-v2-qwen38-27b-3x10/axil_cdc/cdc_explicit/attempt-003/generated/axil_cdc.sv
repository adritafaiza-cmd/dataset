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
    reg                   s_awreq;
    wire                  m_awack;

    // Synchronizer for request
    reg [2:0] s_awreq_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_awreq_sync <= 3'b000;
        else
            s_awreq_sync <= {s_awreq_sync[1:0], s_awreq};
    end

    // Synchronizer for acknowledge
    reg [2:0] m_awack_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_awack_sync <= 3'b000;
        else
            m_awack_sync <= {m_awack_sync[1:0], m_awack};
    end

    // S-side FSM
    reg s_aw_state;
    wire s_aw_idle = ~s_aw_state;
    wire s_aw_wait = s_aw_state;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_aw_state <= 1'b0;
        else if (s_aw_idle && s_axil_awvalid)
            s_aw_state <= 1'b1;
        else if (s_aw_wait && m_awack_sync[2])
            s_aw_state <= 1'b0;
    end

    // Capture payload on accept
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_awaddr_reg <= {ADDR_WIDTH{1'b0}};
            s_awprot_reg <= 3'b000;
            s_awreq      <= 1'b0;
        end
        else if (s_aw_idle && s_axil_awvalid) begin
            s_awaddr_reg <= s_axil_awaddr;
            s_awprot_reg <= s_axil_awprot;
            s_awreq      <= 1'b1;
        end
        else if (s_aw_wait && m_awack_sync[2]) begin
            s_awreq <= 1'b0;
        end
    end

    // M-side: detect rising edge of synchronized request
    reg m_awreq_prev;
    wire m_awreq_edge = s_awreq_sync[2] & ~m_awreq_prev;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_awreq_prev <= 1'b0;
        else
            m_awreq_prev <= s_awreq_sync[2];
    end

    // M-side FSM
    reg m_aw_state;
    wire m_aw_idle = ~m_aw_state;
    wire m_aw_wait = m_aw_state;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_aw_state <= 1'b0;
        else if (m_aw_idle && m_awreq_edge)
            m_aw_state <= 1'b1;
        else if (m_aw_wait && m_axil_awready)
            m_aw_state <= 1'b0;
    end

    // M-side outputs
    assign m_axil_awaddr  = s_awaddr_reg;
    assign m_axil_awprot  = s_awprot_reg;
    assign m_axil_awvalid = m_aw_wait;
    assign m_awack        = m_aw_wait && m_axil_awready;

    // S-side ready
    assign s_axil_awready = s_aw_idle;

    // ========================================================================
    // Write Data Channel: S -> M
    // ========================================================================
    reg  [DATA_WIDTH-1:0] s_wdata_reg;
    reg  [STRB_WIDTH-1:0] s_wstrb_reg;
    reg                   s_wreq;
    wire                  m_wack;

    // Synchronizer for request
    reg [2:0] s_wreq_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_wreq_sync <= 3'b000;
        else
            s_wreq_sync <= {s_wreq_sync[1:0], s_wreq};
    end

    // Synchronizer for acknowledge
    reg [2:0] m_wack_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_wack_sync <= 3'b000;
        else
            m_wack_sync <= {m_wack_sync[1:0], m_wack};
    end

    // S-side FSM
    reg s_w_state;
    wire s_w_idle = ~s_w_state;
    wire s_w_wait = s_w_state;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_w_state <= 1'b0;
        else if (s_w_idle && s_axil_wvalid)
            s_w_state <= 1'b1;
        else if (s_w_wait && m_wack_sync[2])
            s_w_state <= 1'b0;
    end

    // Capture payload on accept
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wdata_reg <= {DATA_WIDTH{1'b0}};
            s_wstrb_reg <= {STRB_WIDTH{1'b0}};
            s_wreq      <= 1'b0;
        end
        else if (s_w_idle && s_axil_wvalid) begin
            s_wdata_reg <= s_axil_wdata;
            s_wstrb_reg <= s_axil_wstrb;
            s_wreq      <= 1'b1;
        end
        else if (s_w_wait && m_wack_sync[2]) begin
            s_wreq <= 1'b0;
        end
    end

    // M-side: detect rising edge of synchronized request
    reg m_wreq_prev;
    wire m_wreq_edge = s_wreq_sync[2] & ~m_wreq_prev;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_wreq_prev <= 1'b0;
        else
            m_wreq_prev <= s_wreq_sync[2];
    end

    // M-side FSM
    reg m_w_state;
    wire m_w_idle = ~m_w_state;
    wire m_w_wait = m_w_state;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_w_state <= 1'b0;
        else if (m_w_idle && m_wreq_edge)
            m_w_state <= 1'b1;
        else if (m_w_wait && m_axil_wready)
            m_w_state <= 1'b0;
    end

    // M-side outputs
    assign m_axil_wdata  = s_wdata_reg;
    assign m_axil_wstrb  = s_wstrb_reg;
    assign m_axil_wvalid = m_w_wait;
    assign m_wack        = m_w_wait && m_axil_wready;

    // S-side ready
    assign s_axil_wready = s_w_idle;

    // ========================================================================
    // Write Response Channel: M -> S
    // ========================================================================
    reg  [1:0] m_bresp_reg;
    reg        m_breq;
    wire       s_back;

    // Synchronizer for request
    reg [2:0] m_breq_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_breq_sync <= 3'b000;
        else
            m_breq_sync <= {m_breq_sync[1:0], m_breq};
    end

    // Synchronizer for acknowledge
    reg [2:0] s_back_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_back_sync <= 3'b000;
        else
            s_back_sync <= {s_back_sync[1:0], s_back};
    end

    // M-side FSM
    reg m_b_state;
    wire m_b_idle = ~m_b_state;
    wire m_b_wait = m_b_state;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_b_state <= 1'b0;
        else if (m_b_idle && m_axil_bvalid)
            m_b_state <= 1'b1;
        else if (m_b_wait && s_back_sync[2])
            m_b_state <= 1'b0;
    end

    // Capture payload on accept
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_bresp_reg <= 2'b00;
            m_breq      <= 1'b0;
        end
        else if (m_b_idle && m_axil_bvalid) begin
            m_bresp_reg <= m_axil_bresp;
            m_breq      <= 1'b1;
        end
        else if (m_b_wait && s_back_sync[2]) begin
            m_breq <= 1'b0;
        end
    end

    // S-side: detect rising edge of synchronized request
    reg s_breq_prev;
    wire s_breq_edge = m_breq_sync[2] & ~s_breq_prev;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_breq_prev <= 1'b0;
        else
            s_breq_prev <= m_breq_sync[2];
    end

    // S-side FSM
    reg s_b_state;
    wire s_b_idle = ~s_b_state;
    wire s_b_wait = s_b_state;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_b_state <= 1'b0;
        else if (s_b_idle && s_breq_edge)
            s_b_state <= 1'b1;
        else if (s_b_wait && s_axil_bready)
            s_b_state <= 1'b0;
    end

    // S-side outputs
    assign s_axil_bresp  = m_bresp_reg;
    assign s_axil_bvalid = s_b_wait;
    assign s_back        = s_b_wait && s_axil_bready;

    // M-side ready
    assign m_axil_bready = m_b_idle;

    // ========================================================================
    // Read Address Channel: S -> M
    // ========================================================================
    reg  [ADDR_WIDTH-1:0] s_araddr_reg;
    reg  [2:0]            s_arprot_reg;
    reg                   s_arreq;
    wire                  m_arack;

    // Synchronizer for request
    reg [2:0] s_arreq_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_arreq_sync <= 3'b000;
        else
            s_arreq_sync <= {s_arreq_sync[1:0], s_arreq};
    end

    // Synchronizer for acknowledge
    reg [2:0] m_arack_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_arack_sync <= 3'b000;
        else
            m_arack_sync <= {m_arack_sync[1:0], m_arack};
    end

    // S-side FSM
    reg s_ar_state;
    wire s_ar_idle = ~s_ar_state;
    wire s_ar_wait = s_ar_state;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_ar_state <= 1'b0;
        else if (s_ar_idle && s_axil_arvalid)
            s_ar_state <= 1'b1;
        else if (s_ar_wait && m_arack_sync[2])
            s_ar_state <= 1'b0;
    end

    // Capture payload on accept
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_araddr_reg <= {ADDR_WIDTH{1'b0}};
            s_arprot_reg <= 3'b000;
            s_arreq      <= 1'b0;
        end
        else if (s_ar_idle && s_axil_arvalid) begin
            s_araddr_reg <= s_axil_araddr;
            s_arprot_reg <= s_axil_arprot;
            s_arreq      <= 1'b1;
        end
        else if (s_ar_wait && m_arack_sync[2]) begin
            s_arreq <= 1'b0;
        end
    end

    // M-side: detect rising edge of synchronized request
    reg m_arreq_prev;
    wire m_arreq_edge = s_arreq_sync[2] & ~m_arreq_prev;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_arreq_prev <= 1'b0;
        else
            m_arreq_prev <= s_arreq_sync[2];
    end

    // M-side FSM
    reg m_ar_state;
    wire m_ar_idle = ~m_ar_state;
    wire m_ar_wait = m_ar_state;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_ar_state <= 1'b0;
        else if (m_ar_idle && m_arreq_edge)
            m_ar_state <= 1'b1;
        else if (m_ar_wait && m_axil_arready)
            m_ar_state <= 1'b0;
    end

    // M-side outputs
    assign m_axil_araddr  = s_araddr_reg;
    assign m_axil_arprot  = s_arprot_reg;
    assign m_axil_arvalid = m_ar_wait;
    assign m_arack        = m_ar_wait && m_axil_arready;

    // S-side ready
    assign s_axil_arready = s_ar_idle;

    // ========================================================================
    // Read Data Channel: M -> S
    // ========================================================================
    reg  [DATA_WIDTH-1:0] m_rdata_reg;
    reg  [1:0]            m_rresp_reg;
    reg                   m_rreq;
    wire                  s_rack;

    // Synchronizer for request
    reg [2:0] m_rreq_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_rreq_sync <= 3'b000;
        else
            m_rreq_sync <= {m_rreq_sync[1:0], m_rreq};
    end

    // Synchronizer for acknowledge
    reg [2:0] s_rack_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_rack_sync <= 3'b000;
        else
            s_rack_sync <= {s_rack_sync[1:0], s_rack};
    end

    // M-side FSM
    reg m_r_state;
    wire m_r_idle = ~m_r_state;
    wire m_r_wait = m_r_state;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_r_state <= 1'b0;
        else if (m_r_idle && m_axil_rvalid)
            m_r_state <= 1'b1;
        else if (m_r_wait && s_rack_sync[2])
            m_r_state <= 1'b0;
    end

    // Capture payload on accept
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rdata_reg <= {DATA_WIDTH{1'b0}};
            m_rresp_reg <= 2'b00;
            m_rreq      <= 1'b0;
        end
        else if (m_r_idle && m_axil_rvalid) begin
            m_rdata_reg <= m_axil_rdata;
            m_rresp_reg <= m_axil_rresp;
            m_rreq      <= 1'b1;
        end
        else if (m_r_wait && s_rack_sync[2]) begin
            m_rreq <= 1'b0;
        end
    end

    // S-side: detect rising edge of synchronized request
    reg s_rreq_prev;
    wire s_rreq_edge = m_rreq_sync[2] & ~s_rreq_prev;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_rreq_prev <= 1'b0;
        else
            s_rreq_prev <= m_rreq_sync[2];
    end

    // S-side FSM
    reg s_r_state;
    wire s_r_idle = ~s_r_state;
    wire s_r_wait = s_r_state;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_r_state <= 1'b0;
        else if (s_r_idle && s_rreq_edge)
            s_r_state <= 1'b1;
        else if (s_r_wait && s_axil_rready)
            s_r_state <= 1'b0;
    end

    // S-side outputs
    assign s_axil_rdata  = m_rdata_reg;
    assign s_axil_rresp  = m_rresp_reg;
    assign s_axil_rvalid = s_r_wait;
    assign s_rack        = s_r_wait && s_axil_rready;

    // M-side ready
    assign m_axil_rready = m_r_idle;

endmodule
