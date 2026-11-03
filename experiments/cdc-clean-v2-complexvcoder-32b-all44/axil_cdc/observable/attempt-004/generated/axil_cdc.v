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

    /*
     * Internal signals for FIFOs
     */
    wire aw_s_ready;
    wire aw_m_valid;
    wire w_s_ready;
    wire w_m_valid;
    wire b_m_ready;
    wire ar_s_ready;
    wire ar_m_valid;
    wire r_m_ready;

    /*
     * AW channel FIFO
     */
    cdc_fifo #(.DATA_WIDTH(ADDR_WIDTH + 3)) aw_cdc_fifo (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_data({s_axil_awaddr, s_axil_awprot}),
        .s_valid(s_axil_awvalid),
        .s_ready(aw_s_ready),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_data({m_axil_awaddr, m_axil_awprot}),
        .m_valid(aw_m_valid),
        .m_ready(m_axil_awready)
    );

    /*
     * W channel FIFO
     */
    cdc_fifo #(.DATA_WIDTH(DATA_WIDTH + STRB_WIDTH)) w_cdc_fifo (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_data({s_axil_wdata, s_axil_wstrb}),
        .s_valid(s_axil_wvalid),
        .s_ready(w_s_ready),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_data({m_axil_wdata, m_axil_wstrb}),
        .m_valid(w_m_valid),
        .m_ready(m_axil_wready)
    );

    /*
     * B channel FIFO
     */
    cdc_fifo #(.DATA_WIDTH(3)) b_cdc_fifo (
        .s_clk(m_clk),
        .s_rst(m_rst),
        .s_data({m_axil_bresp, m_axil_bvalid}),
        .s_valid(m_axil_bvalid),
        .s_ready(b_m_ready),
        .m_clk(s_clk),
        .m_rst(s_rst),
        .m_data({s_axil_bresp, s_axil_bvalid}),
        .m_valid(s_axil_bvalid),
        .m_ready(s_axil_bready)
    );

    /*
     * AR channel FIFO
     */
    cdc_fifo #(.DATA_WIDTH(ADDR_WIDTH + 3)) ar_cdc_fifo (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_data({s_axil_araddr, s_axil_arprot}),
        .s_valid(s_axil_arvalid),
        .s_ready(ar_s_ready),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_data({m_axil_araddr, m_axil_arprot}),
        .m_valid(ar_m_valid),
        .m_ready(m_axil_arready)
    );

    /*
     * R channel FIFO
     */
    cdc_fifo #(.DATA_WIDTH(DATA_WIDTH + 3)) r_cdc_fifo (
        .s_clk(m_clk),
        .s_rst(m_rst),
        .s_data({m_axil_rdata, m_axil_rresp, m_axil_rvalid}),
        .s_valid(m_axil_rvalid),
        .s_ready(r_m_ready),
        .m_clk(s_clk),
        .m_rst(s_rst),
        .m_data({s_axil_rdata, s_axil_rresp, s_axil_rvalid}),
        .m_valid(s_axil_rvalid),
        .m_ready(s_axil_rready)
    );

    /*
     * Assign outputs
     */
    assign s_axil_awready = aw_s_ready;
    assign s_axil_wready  = w_s_ready;
    assign m_axil_awvalid = aw_m_valid;
    assign m_axil_wvalid  = w_m_valid;
    assign m_axil_bready  = b_m_ready;
    assign s_axil_arready = ar_s_ready;
    assign m_axil_arvalid = ar_m_valid;
    assign m_axil_rready  = r_m_ready;

endmodule

module cdc_fifo #
(
    parameter DATA_WIDTH = 32
)
(
    input  wire                   s_clk,
    input  wire                   s_rst,
    input  wire [DATA_WIDTH-1:0]  s_data,
    input  wire                   s_valid,
    output wire                   s_ready,
    input  wire                   m_clk,
    input  wire                   m_rst,
    output wire [DATA_WIDTH-1:0]  m_data,
    output wire                   m_valid,
    input  wire                   m_ready
);

    /*
     * FIFO depth
     */
    localparam DEPTH = 16;
    localparam ADDR_WIDTH = $clog2(DEPTH);

    /*
     * FIFO pointers and flags
     */
    reg [ADDR_WIDTH:0] s_wr_ptr;
    reg [ADDR_WIDTH:0] s_rd_ptr;
    reg [ADDR_WIDTH:0] m_wr_ptr;
    reg [ADDR_WIDTH:0] m_rd_ptr;
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH:0] s_count;
    reg [ADDR_WIDTH:0] m_count;

    /*
     * FIFO flags
     */
    wire full;
    wire empty;

    /*
     * FIFO flags logic
     */
    assign full  = (s_count == DEPTH);
    assign empty = (m_count == 0);

    /*
     * FIFO ready signals
     */
    assign s_ready = ~full;
    assign m_valid = ~empty;

    /*
     * FIFO write logic
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr  <= 0;
            s_rd_ptr  <= 0;
            s_count   <= 0;
        end else if (s_valid && s_ready) begin
            mem[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_data;
            s_wr_ptr <= s_wr_ptr + 1;
            s_count  <= s_count + 1;
        end
    end

    /*
     * FIFO read logic
     */
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_wr_ptr  <= 0;
            m_rd_ptr  <= 0;
            m_count   <= 0;
        end else if (m_valid && m_ready) begin
            m_rd_ptr <= m_rd_ptr + 1;
            m_count  <= m_count - 1;
        end
    end

    /*
     * FIFO data output
     */
    assign m_data = mem[m_rd_ptr[ADDR_WIDTH-1:0]];

endmodule
