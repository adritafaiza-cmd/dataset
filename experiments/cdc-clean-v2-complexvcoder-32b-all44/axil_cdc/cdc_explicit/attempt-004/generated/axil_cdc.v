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

    // Instantiate async FIFOs for each AXI-Lite channel
    async_fifo #(
        .WIDTH(ADDR_WIDTH + 3),
        .DEPTH(2)
    ) aw_fifo (
        .wr_clk(s_clk),
        .wr_rst(s_rst),
        .wr_data({s_axil_awaddr, s_axil_awprot}),
        .wr_en(s_axil_awvalid),
        .wr_full(~s_axil_awready),
        .rd_clk(m_clk),
        .rd_rst(m_rst),
        .rd_data({m_axil_awaddr, m_axil_awprot}),
        .rd_en(m_axil_awvalid),
        .rd_empty(~m_axil_awready)
    );

    async_fifo #(
        .WIDTH(DATA_WIDTH + STRB_WIDTH),
        .DEPTH(2)
    ) w_fifo (
        .wr_clk(s_clk),
        .wr_rst(s_rst),
        .wr_data({s_axil_wdata, s_axil_wstrb}),
        .wr_en(s_axil_wvalid),
        .wr_full(~s_axil_wready),
        .rd_clk(m_clk),
        .rd_rst(m_rst),
        .rd_data({m_axil_wdata, m_axil_wstrb}),
        .rd_en(m_axil_wvalid),
        .rd_empty(~m_axil_wready)
    );

    async_fifo #(
        .WIDTH(3),
        .DEPTH(2)
    ) b_fifo (
        .wr_clk(m_clk),
        .wr_rst(m_rst),
        .wr_data({m_axil_bresp, m_axil_bvalid}),
        .wr_en(m_axil_bvalid),
        .wr_full(~m_axil_bready),
        .rd_clk(s_clk),
        .rd_rst(s_rst),
        .rd_data({s_axil_bresp, s_axil_bvalid}),
        .rd_en(s_axil_bready),
        .rd_empty(~s_axil_bready)
    );

    async_fifo #(
        .WIDTH(ADDR_WIDTH + 3),
        .DEPTH(2)
    ) ar_fifo (
        .wr_clk(s_clk),
        .wr_rst(s_rst),
        .wr_data({s_axil_araddr, s_axil_arprot}),
        .wr_en(s_axil_arvalid),
        .wr_full(~s_axil_arready),
        .rd_clk(m_clk),
        .rd_rst(m_rst),
        .rd_data({m_axil_araddr, m_axil_arprot}),
        .rd_en(m_axil_arvalid),
        .rd_empty(~m_axil_arready)
    );

    async_fifo #(
        .WIDTH(DATA_WIDTH + 3),
        .DEPTH(2)
    ) r_fifo (
        .wr_clk(m_clk),
        .wr_rst(m_rst),
        .wr_data({m_axil_rdata, m_axil_rresp, m_axil_rvalid}),
        .wr_en(m_axil_rvalid),
        .wr_full(~m_axil_rready),
        .rd_clk(s_clk),
        .rd_rst(s_rst),
        .rd_data({s_axil_rdata, s_axil_rresp, s_axil_rvalid}),
        .rd_en(s_axil_rready),
        .rd_empty(~s_axil_rready)
    );

endmodule

module async_fifo #(
    parameter WIDTH = 32,
    parameter DEPTH = 2
)
(
    input  wire wr_clk,
    input  wire wr_rst,
    input  wire [WIDTH-1:0] wr_data,
    input  wire wr_en,
    output wire wr_full,
    input  wire rd_clk,
    input  wire rd_rst,
    output wire [WIDTH-1:0] rd_data,
    input  wire rd_en,
    output wire rd_empty
);

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH)-1:0] wr_ptr;
    reg [$clog2(DEPTH)-1:0] rd_ptr;
    reg [$clog2(DEPTH):0] count;

    reg [WIDTH-1:0] wr_data_reg;
    reg [WIDTH-1:0] rd_data_reg;

    always @(posedge wr_clk or posedge wr_rst) begin
        if (wr_rst) begin
            wr_ptr <= 0;
            count <= 0;
        end else if (wr_en && (count < DEPTH)) begin
            mem[wr_ptr] <= wr_data;
            wr_ptr <= wr_ptr + 1;
            count <= count + 1;
        end
    end

    always @(posedge rd_clk or posedge rd_rst) begin
        if (rd_rst) begin
            rd_ptr <= 0;
            count <= 0;
        end else if (rd_en && (count > 0)) begin
            rd_ptr <= rd_ptr + 1;
            count <= count - 1;
        end
    end

    always @(posedge wr_clk or posedge wr_rst) begin
        if (wr_rst)
            wr_data_reg <= 0;
        else if (wr_en && (count < DEPTH))
            wr_data_reg <= wr_data;
    end

    always @(posedge rd_clk or posedge rd_rst) begin
        if (rd_rst)
            rd_data_reg <= 0;
        else if (rd_en && (count > 0))
            rd_data_reg <= mem[rd_ptr];
    end

    assign wr_full = (count == DEPTH);
    assign rd_empty = (count == 0);
    assign rd_data = rd_data_reg;

endmodule
