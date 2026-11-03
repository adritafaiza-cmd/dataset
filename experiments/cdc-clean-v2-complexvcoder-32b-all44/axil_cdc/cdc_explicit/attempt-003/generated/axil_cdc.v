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
     * Internal signals
     */
    wire [ADDR_WIDTH+2:0]         aw_data_in;
    wire [ADDR_WIDTH+2:0]         aw_data_out;
    wire [DATA_WIDTH+STRB_WIDTH:0] w_data_in;
    wire [DATA_WIDTH+STRB_WIDTH:0] w_data_out;
    wire [1:0]                    b_data_in;
    wire [1:0]                    b_data_out;
    wire [ADDR_WIDTH+2:0]         ar_data_in;
    wire [ADDR_WIDTH+2:0]         ar_data_out;
    wire [DATA_WIDTH+1:0]         r_data_in;
    wire [DATA_WIDTH+1:0]         r_data_out;

    /*
     * AW channel asynchronous FIFO
     */
    async_fifo #(
        .DATA_WIDTH(ADDR_WIDTH+3)
    ) aw_fifo (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_data(aw_data_in),
        .s_valid(s_axil_awvalid),
        .s_ready(s_axil_awready),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_data(aw_data_out),
        .m_valid(m_axil_awvalid),
        .m_ready(m_axil_awready)
    );

    /*
     * W channel asynchronous FIFO
     */
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH+STRB_WIDTH+1)
    ) w_fifo (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_data(w_data_in),
        .s_valid(s_axil_wvalid),
        .s_ready(s_axil_wready),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_data(w_data_out),
        .m_valid(m_axil_wvalid),
        .m_ready(m_axil_wready)
    );

    /*
     * B channel asynchronous FIFO
     */
    async_fifo #(
        .DATA_WIDTH(2)
    ) b_fifo (
        .s_clk(m_clk),
        .s_rst(m_rst),
        .s_data(b_data_in),
        .s_valid(m_axil_bvalid),
        .s_ready(m_axil_bready),
        .m_clk(s_clk),
        .m_rst(s_rst),
        .m_data(b_data_out),
        .m_valid(s_axil_bvalid),
        .m_ready(s_axil_bready)
    );

    /*
     * AR channel asynchronous FIFO
     */
    async_fifo #(
        .DATA_WIDTH(ADDR_WIDTH+3)
    ) ar_fifo (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_data(ar_data_in),
        .s_valid(s_axil_arvalid),
        .s_ready(s_axil_arready),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_data(ar_data_out),
        .m_valid(m_axil_arvalid),
        .m_ready(m_axil_arready)
    );

    /*
     * R channel asynchronous FIFO
     */
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH+2)
    ) r_fifo (
        .s_clk(m_clk),
        .s_rst(m_rst),
        .s_data(r_data_in),
        .s_valid(m_axil_rvalid),
        .s_ready(m_axil_rready),
        .m_clk(s_clk),
        .m_rst(s_rst),
        .m_data(r_data_out),
        .m_valid(s_axil_rvalid),
        .m_ready(s_axil_rready)
    );

    /*
     * AW channel data packing
     */
    assign aw_data_in = {s_axil_awaddr, s_axil_awprot};

    /*
     * AW channel data unpacking
     */
    assign m_axil_awaddr = aw_data_out[ADDR_WIDTH+2:3];
    assign m_axil_awprot = aw_data_out[2:0];

    /*
     * W channel data packing
     */
    assign w_data_in = {s_axil_wdata, s_axil_wstrb, s_axil_wvalid};

    /*
     * W channel data unpacking
     */
    assign m_axil_wdata = w_data_out[DATA_WIDTH+STRB_WIDTH:STRB_WIDTH+1];
    assign m_axil_wstrb = w_data_out[STRB_WIDTH:1];
    assign m_axil_wvalid = w_data_out[0];

    /*
     * B channel data packing
     */
    assign b_data_in = m_axil_bresp;

    /*
     * B channel data unpacking
     */
    assign s_axil_bresp = b_data_out;

    /*
     * AR channel data packing
     */
    assign ar_data_in = {s_axil_araddr, s_axil_arprot};

    /*
     * AR channel data unpacking
     */
    assign m_axil_araddr = ar_data_out[ADDR_WIDTH+2:3];
    assign m_axil_arprot = ar_data_out[2:0];

    /*
     * R channel data packing
     */
    assign r_data_in = {m_axil_rdata, m_axil_rresp, m_axil_rvalid};

    /*
     * R channel data unpacking
     */
    assign s_axil_rdata = r_data_out[DATA_WIDTH+1:2];
    assign s_axil_rresp = r_data_out[1:0];
    assign s_axil_rvalid = r_data_out[0];

endmodule

module async_fifo #
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

    localparam DEPTH = 16;
    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
    reg [ADDR_WIDTH:0] cnt;

    wire full, empty;

    assign full  = (cnt == DEPTH);
    assign empty = (cnt == 0);

    assign s_ready = ~full;
    assign m_valid = ~empty;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wr_ptr <= 0;
            cnt  <= 0;
        end else if (s_valid && s_ready) begin
            mem[wr_ptr] <= s_data;
            wr_ptr <= wr_ptr + 1;
            cnt  <= cnt + 1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rd_ptr <= 0;
            cnt  <= 0;
        end else if (m_valid && m_ready) begin
            rd_ptr <= rd_ptr + 1;
            cnt  <= cnt - 1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_data <= 0;
        end else if (m_valid && m_ready) begin
            m_data <= mem[rd_ptr];
        end
    end

endmodule
