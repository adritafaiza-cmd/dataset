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

    // CDC FIFO instances
    cdc_fifo #(.DATA_WIDTH(ADDR_WIDTH + 3), .DEPTH(16)) aw_fifo (
        .clk_wr(s_clk),
        .rst_wr(s_rst),
        .clk_rd(m_clk),
        .rst_rd(m_rst),
        .data_in({s_axil_awaddr, s_axil_awprot}),
        .wr_en(s_axil_awvalid),
        .rd_en(m_axil_awready),
        .data_out({m_axil_awaddr, m_axil_awprot}),
        .empty(m_axil_awvalid),
        .full(),
        .ack(s_axil_awready)
    );

    cdc_fifo #(.DATA_WIDTH(DATA_WIDTH + STRB_WIDTH), .DEPTH(16)) w_fifo (
        .clk_wr(s_clk),
        .rst_wr(s_rst),
        .clk_rd(m_clk),
        .rst_rd(m_rst),
        .data_in({s_axil_wdata, s_axil_wstrb}),
        .wr_en(s_axil_wvalid),
        .rd_en(m_axil_wready),
        .data_out({m_axil_wdata, m_axil_wstrb}),
        .empty(m_axil_wvalid),
        .full(),
        .ack(s_axil_wready)
    );

    cdc_fifo #(.DATA_WIDTH(2), .DEPTH(16)) b_fifo (
        .clk_wr(m_clk),
        .rst_wr(m_rst),
        .clk_rd(s_clk),
        .rst_rd(s_rst),
        .data_in(m_axil_bresp),
        .wr_en(m_axil_bvalid),
        .rd_en(s_axil_bready),
        .data_out(s_axil_bresp),
        .empty(s_axil_bvalid),
        .full(),
        .ack(m_axil_bready)
    );

    cdc_fifo #(.DATA_WIDTH(ADDR_WIDTH + 3), .DEPTH(16)) ar_fifo (
        .clk_wr(s_clk),
        .rst_wr(s_rst),
        .clk_rd(m_clk),
        .rst_rd(m_rst),
        .data_in({s_axil_araddr, s_axil_arprot}),
        .wr_en(s_axil_arvalid),
        .rd_en(m_axil_arready),
        .data_out({m_axil_araddr, m_axil_arprot}),
        .empty(m_axil_arvalid),
        .full(),
        .ack(s_axil_arready)
    );

    cdc_fifo #(.DATA_WIDTH(DATA_WIDTH + 2), .DEPTH(16)) r_fifo (
        .clk_wr(m_clk),
        .rst_wr(m_rst),
        .clk_rd(s_clk),
        .rst_rd(s_rst),
        .data_in({m_axil_rdata, m_axil_rresp}),
        .wr_en(m_axil_rvalid),
        .rd_en(s_axil_rready),
        .data_out({s_axil_rdata, s_axil_rresp}),
        .empty(s_axil_rvalid),
        .full(),
        .ack(m_axil_rready)
    );

endmodule

module cdc_fifo #
(
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 16
)
(
    input  wire                   clk_wr,
    input  wire                   rst_wr,
    input  wire                   clk_rd,
    input  wire                   rst_rd,
    input  wire [DATA_WIDTH-1:0]  data_in,
    input  wire                   wr_en,
    input  wire                   rd_en,
    output wire [DATA_WIDTH-1:0]  data_out,
    output wire                   empty,
    output wire                   full,
    input  wire                   ack
);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH):0] wr_ptr;
    reg [$clog2(DEPTH):0] rd_ptr;
    reg [$clog2(DEPTH):0] rd_ptr_gray;
    reg [$clog2(DEPTH):0] rd_ptr_gray_sync;

    // Write Pointer Logic
    always @(posedge clk_wr or posedge rst_wr) begin
        if (rst_wr) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr] <= data_in;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read Pointer Logic
    always @(posedge clk_rd or posedge rst_rd) begin
        if (rst_rd) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= {rd_ptr[$clog2(DEPTH)-1:0] ^ rd_ptr[$clog2(DEPTH):1]};
        end
    end

    // Gray Code Synchronization
    reg [$clog2(DEPTH):0] rd_ptr_gray_sync_reg;

    always @(posedge clk_wr or posedge rst_wr) begin
        if (rst_wr) begin
            rd_ptr_gray_sync_reg <= 0;
            rd_ptr_gray_sync <= 0;
        end else begin
            rd_ptr_gray_sync_reg <= rd_ptr_gray_sync;
            rd_ptr_gray_sync <= rd_ptr_gray;
        end
    end

    // Data Output
    reg [$clog2(DEPTH):0] rd_ptr_sync;

    always @(posedge clk_wr or posedge rst_wr) begin
        if (rst_wr) begin
            rd_ptr_sync <= 0;
        end else begin
            rd_ptr_sync <= {rd_ptr_gray_sync_reg[$clog2(DEPTH)-1:0] ^ rd_ptr_gray_sync[$clog2(DEPTH):1]};
        end
    end

    assign data_out = mem[rd_ptr_sync];

    // Empty and Full Flags
    reg [$clog2(DEPTH):0] wr_ptr_gray_sync;

    always @(posedge clk_rd or posedge rst_rd) begin
        if (rst_rd) begin
            wr_ptr_gray_sync <= 0;
        end else begin
            wr_ptr_gray_sync <= {wr_ptr[$clog2(DEPTH)-1:0] ^ wr_ptr[$clog2(DEPTH):1]};
        end
    end

    assign empty = (wr_ptr_gray_sync == rd_ptr_gray);
    assign full = (wr_ptr_gray == {rd_ptr_gray_sync[$clog2(DEPTH)-1:0] ^ ~rd_ptr_gray_sync[$clog2(DEPTH):1]});

endmodule
