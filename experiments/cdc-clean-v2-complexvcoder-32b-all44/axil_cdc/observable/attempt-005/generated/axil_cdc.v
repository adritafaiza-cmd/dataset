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

    // FIFO instances for each AXI channel
    cdc_fifo #(.DATA_WIDTH(ADDR_WIDTH + 3)) aw_cdc_fifo (
        .write_clk(s_clk),
        .write_rst(s_rst),
        .write_data({s_axil_awaddr, s_axil_awprot}),
        .write_en(s_axil_awvalid),
        .write_full_n(s_axil_awready),
        .read_clk(m_clk),
        .read_rst(m_rst),
        .read_data({m_axil_awaddr, m_axil_awprot}),
        .read_valid(m_axil_awvalid),
        .read_ack(m_axil_awready)
    );

    cdc_fifo #(.DATA_WIDTH(DATA_WIDTH + STRB_WIDTH)) w_cdc_fifo (
        .write_clk(s_clk),
        .write_rst(s_rst),
        .write_data({s_axil_wdata, s_axil_wstrb}),
        .write_en(s_axil_wvalid),
        .write_full_n(s_axil_wready),
        .read_clk(m_clk),
        .read_rst(m_rst),
        .read_data({m_axil_wdata, m_axil_wstrb}),
        .read_valid(m_axil_wvalid),
        .read_ack(m_axil_wready)
    );

    cdc_fifo #(.DATA_WIDTH(3)) b_cdc_fifo (
        .write_clk(m_clk),
        .write_rst(m_rst),
        .write_data({m_axil_bresp, m_axil_bvalid}),
        .write_en(m_axil_bvalid),
        .write_full_n(m_axil_bready),
        .read_clk(s_clk),
        .read_rst(s_rst),
        .read_data({s_axil_bresp, s_axil_bvalid}),
        .read_valid(s_axil_bvalid),
        .read_ack(s_axil_bready)
    );

    cdc_fifo #(.DATA_WIDTH(ADDR_WIDTH + 3)) ar_cdc_fifo (
        .write_clk(s_clk),
        .write_rst(s_rst),
        .write_data({s_axil_araddr, s_axil_arprot}),
        .write_en(s_axil_arvalid),
        .write_full_n(s_axil_arready),
        .read_clk(m_clk),
        .read_rst(m_rst),
        .read_data({m_axil_araddr, m_axil_arprot}),
        .read_valid(m_axil_arvalid),
        .read_ack(m_axil_arready)
    );

    cdc_fifo #(.DATA_WIDTH(DATA_WIDTH + 2)) r_cdc_fifo (
        .write_clk(m_clk),
        .write_rst(m_rst),
        .write_data({m_axil_rdata, m_axil_rresp, m_axil_rvalid}),
        .write_en(m_axil_rvalid),
        .write_full_n(m_axil_rready),
        .read_clk(s_clk),
        .read_rst(s_rst),
        .read_data({s_axil_rdata, s_axil_rresp, s_axil_rvalid}),
        .read_valid(s_axil_rvalid),
        .read_ack(s_axil_rready)
    );

endmodule

module cdc_fifo #
(
    parameter DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 16
)
(
    input  wire                   write_clk,
    input  wire                   write_rst,
    input  wire [DATA_WIDTH-1:0]  write_data,
    input  wire                   write_en,
    output wire                   write_full_n,
    input  wire                   read_clk,
    input  wire                   read_rst,
    output wire [DATA_WIDTH-1:0]  read_data,
    output wire                   read_valid,
    input  wire                   read_ack
);

    reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];
    reg [$clog2(FIFO_DEPTH)-1:0] write_ptr, read_ptr;
    reg [$clog2(FIFO_DEPTH):0] count;

    // Write side
    always @(posedge write_clk or posedge write_rst) begin
        if (write_rst) begin
            write_ptr <= 0;
            count <= 0;
        end else if (write_en && count < FIFO_DEPTH) begin
            mem[write_ptr] <= write_data;
            write_ptr <= write_ptr + 1;
            count <= count + 1;
        end
    end

    // Read side
    always @(posedge read_clk or posedge read_rst) begin
        if (read_rst) begin
            read_ptr <= 0;
            count <= 0;
        end else if (read_ack && count > 0) begin
            read_ptr <= read_ptr + 1;
            count <= count - 1;
        end
    end

    assign read_data = mem[read_ptr];
    assign read_valid = (count > 0);
    assign write_full_n = (count < FIFO_DEPTH);

endmodule
