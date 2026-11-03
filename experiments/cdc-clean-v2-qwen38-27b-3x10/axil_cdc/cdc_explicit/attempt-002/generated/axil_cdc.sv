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

    assign s_axil_awready = ~s_awreq;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_awreq <= 1'b0;
        end else begin
            if (s_axil_awvalid && ~s_awreq) begin
                s_awaddr_reg <= s_axil_awaddr;
                s_awprot_reg <= s_axil_awprot;
                s_awreq <= 1'b1;
            end else if (m_awack) begin
                s_awreq <= 1'b0;
            end
        end
    end

    // Synchronize request to M domain
    reg [2:0] m_awreq_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_awreq_sync <= 3'b000;
        else
            m_awreq_sync <= {m_awreq_sync[1:0], s_awreq};
    end

    wire m_awreq_stable = m_awreq_sync[2] & m_awreq_sync[1];

    // Capture payload in M domain when request is stable
    reg [ADDR_WIDTH-1:0] m_awaddr_reg;
    reg [2:0]            m_awprot_reg;
    reg                  m_awcaptured;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_awcaptured <= 1'b0;
        end else begin
            if (m_awreq_stable && ~m_awcaptured) begin
                m_awaddr_reg <= s_awaddr_reg;
                m_awprot_reg <= s_awprot_reg;
                m_awcaptured <= 1'b1;
            end else if (m_axil_awvalid && m_axil_awready) begin
                m_awcaptured <= 1'b0;
            end
        end
    end

    assign m_axil_awaddr  = m_awaddr_reg;
    assign m_axil_awprot  = m_awprot_reg;
    assign m_axil_awvalid = m_awcaptured;

    // Synchronize acknowledge back to S domain
    wire m_awack_raw = m_axil_awvalid && m_axil_awready;
    reg [2:0] s_awack_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_awack_sync <= 3'b000;
        else
            s_awack_sync <= {s_awack_sync[1:0], m_awack_raw};
    end
    assign m_awack = s_awack_sync[2] & s_awack_sync[1];

    // ========================================================================
    // Write Data Channel: S -> M
    // ========================================================================
    reg  [DATA_WIDTH-1:0] s_wdata_reg;
    reg  [STRB_WIDTH-1:0] s_wstrb_reg;
    reg                   s_wreq;
    wire                  m_wack;

    assign s_axil_wready = ~s_wreq;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wreq <= 1'b0;
        end else begin
            if (s_axil_wvalid && ~s_wreq) begin
                s_wdata_reg <= s_axil_wdata;
                s_wstrb_reg <= s_axil_wstrb;
                s_wreq <= 1'b1;
            end else if (m_wack) begin
                s_wreq <= 1'b0;
            end
        end
    end

    // Synchronize request to M domain
    reg [2:0] m_wreq_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_wreq_sync <= 3'b000;
        else
            m_wreq_sync <= {m_wreq_sync[1:0], s_wreq};
    end

    wire m_wreq_stable = m_wreq_sync[2] & m_wreq_sync[1];

    // Capture payload in M domain when request is stable
    reg [DATA_WIDTH-1:0] m_wdata_reg;
    reg [STRB_WIDTH-1:0] m_wstrb_reg;
    reg                  m_wcaptured;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_wcaptured <= 1'b0;
        end else begin
            if (m_wreq_stable && ~m_wcaptured) begin
                m_wdata_reg <= s_wdata_reg;
                m_wstrb_reg <= s_wstrb_reg;
                m_wcaptured <= 1'b1;
            end else if (m_axil_wvalid && m_axil_wready) begin
                m_wcaptured <= 1'b0;
            end
        end
    end

    assign m_axil_wdata  = m_wdata_reg;
    assign m_axil_wstrb  = m_wstrb_reg;
    assign m_axil_wvalid = m_wcaptured;

    // Synchronize acknowledge back to S domain
    wire m_wack_raw = m_axil_wvalid && m_axil_wready;
    reg [2:0] s_wack_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_wack_sync <= 3'b000;
        else
            s_wack_sync <= {s_wack_sync[1:0], m_wack_raw};
    end
    assign m_wack = s_wack_sync[2] & s_wack_sync[1];

    // ========================================================================
    // Write Response Channel: M -> S
    // ========================================================================
    reg  [1:0] m_bresp_reg;
    reg        m_breq;
    wire       s_back;

    assign m_axil_bready = ~m_breq;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_breq <= 1'b0;
        end else begin
            if (m_axil_bvalid && ~m_breq) begin
                m_bresp_reg <= m_axil_bresp;
                m_breq <= 1'b1;
            end else if (s_back) begin
                m_breq <= 1'b0;
            end
        end
    end

    // Synchronize request to S domain
    reg [2:0] s_breq_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_breq_sync <= 3'b000;
        else
            s_breq_sync <= {s_breq_sync[1:0], m_breq};
    end

    wire s_breq_stable = s_breq_sync[2] & s_breq_sync[1];

    // Capture payload in S domain when request is stable
    reg [1:0] s_bresp_reg;
    reg       s_bcaptured;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_bcaptured <= 1'b0;
        end else begin
            if (s_breq_stable && ~s_bcaptured) begin
                s_bresp_reg <= m_bresp_reg;
                s_bcaptured <= 1'b1;
            end else if (s_axil_bvalid && s_axil_bready) begin
                s_bcaptured <= 1'b0;
            end
        end
    end

    assign s_axil_bresp  = s_bresp_reg;
    assign s_axil_bvalid = s_bcaptured;

    // Synchronize acknowledge back to M domain
    wire s_back_raw = s_axil_bvalid && s_axil_bready;
    reg [2:0] m_back_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_back_sync <= 3'b000;
        else
            m_back_sync <= {m_back_sync[1:0], s_back_raw};
    end
    assign s_back = m_back_sync[2] & m_back_sync[1];

    // ========================================================================
    // Read Address Channel: S -> M
    // ========================================================================
    reg  [ADDR_WIDTH-1:0] s_araddr_reg;
    reg  [2:0]            s_arprot_reg;
    reg                   s_arreq;
    wire                  m_arack;

    assign s_axil_arready = ~s_arreq;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_arreq <= 1'b0;
        end else begin
            if (s_axil_arvalid && ~s_arreq) begin
                s_araddr_reg <= s_axil_araddr;
                s_arprot_reg <= s_axil_arprot;
                s_arreq <= 1'b1;
            end else if (m_arack) begin
                s_arreq <= 1'b0;
            end
        end
    end

    // Synchronize request to M domain
    reg [2:0] m_arreq_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_arreq_sync <= 3'b000;
        else
            m_arreq_sync <= {m_arreq_sync[1:0], s_arreq};
    end

    wire m_arreq_stable = m_arreq_sync[2] & m_arreq_sync[1];

    // Capture payload in M domain when request is stable
    reg [ADDR_WIDTH-1:0] m_araddr_reg;
    reg [2:0]            m_arprot_reg;
    reg                  m_arcaptured;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_arcaptured <= 1'b0;
        end else begin
            if (m_arreq_stable && ~m_arcaptured) begin
                m_araddr_reg <= s_araddr_reg;
                m_arprot_reg <= s_arprot_reg;
                m_arcaptured <= 1'b1;
            end else if (m_axil_arvalid && m_axil_arready) begin
                m_arcaptured <= 1'b0;
            end
        end
    end

    assign m_axil_araddr  = m_araddr_reg;
    assign m_axil_arprot  = m_arprot_reg;
    assign m_axil_arvalid = m_arcaptured;

    // Synchronize acknowledge back to S domain
    wire m_arack_raw = m_axil_arvalid && m_axil_arready;
    reg [2:0] s_arack_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_arack_sync <= 3'b000;
        else
            s_arack_sync <= {s_arack_sync[1:0], m_arack_raw};
    end
    assign m_arack = s_arack_sync[2] & s_arack_sync[1];

    // ========================================================================
    // Read Data Channel: M -> S
    // ========================================================================
    reg  [DATA_WIDTH-1:0] m_rdata_reg;
    reg  [1:0]            m_rresp_reg;
    reg                   m_rreq;
    wire                  s_rack;

    assign m_axil_rready = ~m_rreq;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rreq <= 1'b0;
        end else begin
            if (m_axil_rvalid && ~m_rreq) begin
                m_rdata_reg <= m_axil_rdata;
                m_rresp_reg <= m_axil_rresp;
                m_rreq <= 1'b1;
            end else if (s_rack) begin
                m_rreq <= 1'b0;
            end
        end
    end

    // Synchronize request to S domain
    reg [2:0] s_rreq_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_rreq_sync <= 3'b000;
        else
            s_rreq_sync <= {s_rreq_sync[1:0], m_rreq};
    end

    wire s_rreq_stable = s_rreq_sync[2] & s_rreq_sync[1];

    // Capture payload in S domain when request is stable
    reg [DATA_WIDTH-1:0] s_rdata_reg;
    reg [1:0]            s_rresp_reg;
    reg                  s_rcaptured;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_rcaptured <= 1'b0;
        end else begin
            if (s_rreq_stable && ~s_rcaptured) begin
                s_rdata_reg <= m_rdata_reg;
                s_rresp_reg <= m_rresp_reg;
                s_rcaptured <= 1'b1;
            end else if (s_axil_rvalid && s_axil_rready) begin
                s_rcaptured <= 1'b0;
            end
        end
    end

    assign s_axil_rdata  = s_rdata_reg;
    assign s_axil_rresp  = s_rresp_reg;
    assign s_axil_rvalid = s_rcaptured;

    // Synchronize acknowledge back to M domain
    wire s_rack_raw = s_axil_rvalid && s_axil_rready;
    reg [2:0] m_rack_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_rack_sync <= 3'b000;
        else
            m_rack_sync <= {m_rack_sync[1:0], s_rack_raw};
    end
    assign s_rack = m_rack_sync[2] & m_rack_sync[1];

endmodule
