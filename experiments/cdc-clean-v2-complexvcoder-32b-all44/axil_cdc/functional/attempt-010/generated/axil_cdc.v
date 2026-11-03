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

    // Internal signals
    reg [ADDR_WIDTH+3+1-1:0] s_aw_buffer;
    reg [DATA_WIDTH+STRB_WIDTH+1-1:0] s_w_buffer;
    reg [ADDR_WIDTH+3+1-1:0] s_ar_buffer;
    reg [ADDR_WIDTH+3+1-1:0] m_aw_buffer;
    reg [DATA_WIDTH+STRB_WIDTH+1-1:0] m_w_buffer;
    reg [ADDR_WIDTH+3+1-1:0] m_ar_buffer;
    reg s_aw_valid, s_w_valid, s_ar_valid;
    reg m_aw_valid, m_w_valid, m_ar_valid;
    reg s_aw_ready, s_w_ready, s_ar_ready;
    reg m_aw_ready, m_w_ready, m_ar_ready;
    reg [1:0] s_bresp;
    reg s_bvalid;
    reg [DATA_WIDTH-1:0] s_rdata;
    reg [1:0] s_rresp;
    reg s_rvalid;
    reg m_bready;
    reg m_rready;

    // Cross-domain synchronization for AW
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_aw_buffer <= 0;
            s_aw_valid <= 0;
        end else if (s_axil_awvalid && s_aw_ready) begin
            s_aw_buffer <= {s_axil_awaddr, s_axil_awprot, 1'b1};
            s_aw_valid <= 1;
        end else if (m_aw_ready && m_aw_valid) begin
            s_aw_valid <= 0;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_aw_buffer <= 0;
            m_aw_ready <= 0;
        end else if (!m_aw_valid && s_aw_valid) begin
            m_aw_buffer <= s_aw_buffer;
            m_aw_valid <= 1;
            m_aw_ready <= 1;
        end else if (m_aw_valid && m_aw_ready) begin
            m_aw_valid <= 0;
            m_aw_ready <= 0;
        end
    end

    assign s_axil_awready = !s_aw_valid;
    assign m_axil_awaddr = m_aw_buffer[ADDR_WIDTH+3+1-1:3];
    assign m_axil_awprot = m_aw_buffer[2:0];

    // Cross-domain synchronization for W
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_w_buffer <= 0;
            s_w_valid <= 0;
        end else if (s_axil_wvalid && s_w_ready) begin
            s_w_buffer <= {s_axil_wdata, s_axil_wstrb, 1'b1};
            s_w_valid <= 1;
        end else if (m_w_ready && m_w_valid) begin
            s_w_valid <= 0;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_w_buffer <= 0;
            m_w_ready <= 0;
        end else if (!m_w_valid && s_w_valid) begin
            m_w_buffer <= s_w_buffer;
            m_w_valid <= 1;
            m_w_ready <= 1;
        end else if (m_w_valid && m_w_ready) begin
            m_w_valid <= 0;
            m_w_ready <= 0;
        end
    end

    assign s_axil_wready = !s_w_valid;
    assign m_axil_wdata = m_w_buffer[DATA_WIDTH+STRB_WIDTH+1-1:STRB_WIDTH];
    assign m_axil_wstrb = m_w_buffer[STRB_WIDTH-1:0];

    // Cross-domain synchronization for B
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_bresp <= 0;
            s_bvalid <= 0;
        end else if (m_axil_bvalid && m_bready) begin
            s_bresp <= m_axil_bresp;
            s_bvalid <= 1;
        end else if (s_bvalid && s_axil_bready) begin
            s_bvalid <= 0;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_bready <= 0;
        end else if (m_axil_bvalid && !s_bvalid) begin
            m_bready <= 1;
        end else if (m_bready && m_axil_bvalid && m_axil_bready) begin
            m_bready <= 0;
        end
    end

    assign s_axil_bresp = s_bresp;
    assign s_axil_bvalid = s_bvalid;

    // Cross-domain synchronization for AR
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_ar_buffer <= 0;
            s_ar_valid <= 0;
        end else if (s_axil_arvalid && s_ar_ready) begin
            s_ar_buffer <= {s_axil_araddr, s_axil_arprot, 1'b1};
            s_ar_valid <= 1;
        end else if (m_ar_ready && m_ar_valid) begin
            s_ar_valid <= 0;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_ar_buffer <= 0;
            m_ar_ready <= 0;
        end else if (!m_ar_valid && s_ar_valid) begin
            m_ar_buffer <= s_ar_buffer;
            m_ar_valid <= 1;
            m_ar_ready <= 1;
        end else if (m_ar_valid && m_ar_ready) begin
            m_ar_valid <= 0;
            m_ar_ready <= 0;
        end
    end

    assign s_axil_arready = !s_ar_valid;
    assign m_axil_araddr = m_ar_buffer[ADDR_WIDTH+3+1-1:3];
    assign m_axil_arprot = m_ar_buffer[2:0];

    // Cross-domain synchronization for R
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_rdata <= 0;
            s_rresp <= 0;
            s_rvalid <= 0;
        end else if (m_axil_rvalid && m_rready) begin
            s_rdata <= m_axil_rdata;
            s_rresp <= m_axil_rresp;
            s_rvalid <= 1;
        end else if (s_rvalid && s_axil_rready) begin
            s_rvalid <= 0;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rready <= 0;
        end else if (m_axil_rvalid && !s_rvalid) begin
            m_rready <= 1;
        end else if (m_rready && m_axil_rvalid && m_axil_rready) begin
            m_rready <= 0;
        end
    end

    assign s_axil_rdata = s_rdata;
    assign s_axil_rresp = s_rresp;
    assign s_axil_rvalid = s_rvalid;

endmodule
