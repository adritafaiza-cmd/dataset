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

    // FIFO for AW channel
    cdc_fifo #(.DATA_WIDTH(ADDR_WIDTH+3)) aw_fifo (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .in_data({s_axil_awaddr, s_axil_awprot}),
        .in_valid(s_axil_awvalid),
        .in_ready(s_axil_awready),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .out_data({m_axil_awaddr, m_axil_awprot}),
        .out_valid(m_axil_awvalid),
        .out_ready(m_axil_awready)
    );

    // FIFO for W channel
    cdc_fifo #(.DATA_WIDTH(DATA_WIDTH+STRB_WIDTH)) w_fifo (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .in_data({s_axil_wdata, s_axil_wstrb}),
        .in_valid(s_axil_wvalid),
        .in_ready(s_axil_wready),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .out_data({m_axil_wdata, m_axil_wstrb}),
        .out_valid(m_axil_wvalid),
        .out_ready(m_axil_wready)
    );

    // FIFO for B channel
    cdc_fifo #(.DATA_WIDTH(3)) b_fifo (
        .s_clk(m_clk),
        .s_rst(m_rst),
        .in_data({m_axil_bresp, m_axil_bvalid}),
        .in_valid(m_axil_bvalid),
        .in_ready(m_axil_bready),
        .m_clk(s_clk),
        .m_rst(s_rst),
        .out_data({s_axil_bresp, s_axil_bvalid}),
        .out_valid(s_axil_bvalid),
        .out_ready(s_axil_bready)
    );

    // FIFO for AR channel
    cdc_fifo #(.DATA_WIDTH(ADDR_WIDTH+3)) ar_fifo (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .in_data({s_axil_araddr, s_axil_arprot}),
        .in_valid(s_axil_arvalid),
        .in_ready(s_axil_arready),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .out_data({m_axil_araddr, m_axil_arprot}),
        .out_valid(m_axil_arvalid),
        .out_ready(m_axil_arready)
    );

    // FIFO for R channel
    cdc_fifo #(.DATA_WIDTH(DATA_WIDTH+3)) r_fifo (
        .s_clk(m_clk),
        .s_rst(m_rst),
        .in_data({m_axil_rdata, m_axil_rresp, m_axil_rvalid}),
        .in_valid(m_axil_rvalid),
        .in_ready(m_axil_rready),
        .m_clk(s_clk),
        .m_rst(s_rst),
        .out_data({s_axil_rdata, s_axil_rresp, s_axil_rvalid}),
        .out_valid(s_axil_rvalid),
        .out_ready(s_axil_rready)
    );

endmodule

module cdc_fifo #
(
    parameter DATA_WIDTH = 32
)
(
    input  wire                   s_clk,
    input  wire                   s_rst,
    input  wire [DATA_WIDTH-1:0]  in_data,
    input  wire                   in_valid,
    output wire                   in_ready,
    input  wire                   m_clk,
    input  wire                   m_rst,
    output wire [DATA_WIDTH-1:0]  out_data,
    output wire                   out_valid,
    input  wire                   out_ready
);

    reg [DATA_WIDTH-1:0] s_data_reg;
    reg                  s_valid_reg;
    reg [DATA_WIDTH-1:0] m_data_reg;
    reg                  m_valid_reg;
    reg                  m_ready_reg;

    // Synchronous domain (s_clk)
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_data_reg  <= {DATA_WIDTH{1'b0}};
            s_valid_reg <= 1'b0;
        end else begin
            if (in_valid && !s_valid_reg) begin
                s_data_reg  <= in_data;
                s_valid_reg <= 1'b1;
            end else if (m_ready_reg) begin
                s_valid_reg <= 1'b0;
            end
        end
    end

    assign in_ready = !s_valid_reg;

    // Cross-domain synchronization
    reg [1:0] sync_valid;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            sync_valid <= 2'b00;
            m_data_reg <= {DATA_WIDTH{1'b0}};
            m_valid_reg <= 1'b0;
        end else begin
            sync_valid[0] <= s_valid_reg;
            sync_valid[1] <= sync_valid[0];

            if (!m_valid_reg && sync_valid[1]) begin
                m_data_reg  <= s_data_reg;
                m_valid_reg <= 1'b1;
            end else if (out_ready) begin
                m_valid_reg <= 1'b0;
            end
        end
    end

    assign out_data = m_data_reg;
    assign out_valid = m_valid_reg;

    // Back-pressure signal
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_ready_reg <= 1'b0;
        end else begin
            m_ready_reg <= out_ready;
        end
    end

endmodule
