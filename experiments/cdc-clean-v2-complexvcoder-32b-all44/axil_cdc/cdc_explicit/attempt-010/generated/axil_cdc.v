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

    // Internal signals for FIFOs
    wire [ADDR_WIDTH+2:0]         aw_fifo_dout;
    wire                          aw_fifo_full;
    wire                          aw_fifo_empty;
    wire                          aw_fifo_rd_en;

    wire [DATA_WIDTH+STRB_WIDTH-1:0] w_fifo_dout;
    wire                          w_fifo_full;
    wire                          w_fifo_empty;
    wire                          w_fifo_rd_en;

    wire [ADDR_WIDTH+2:0]         ar_fifo_dout;
    wire                          ar_fifo_full;
    wire                          ar_fifo_empty;
    wire                          ar_fifo_rd_en;

    wire [1:0]                    b_fifo_dout;
    wire                          b_fifo_full;
    wire                          b_fifo_empty;
    wire                          b_fifo_rd_en;

    wire [DATA_WIDTH+1:0]         r_fifo_dout;
    wire                          r_fifo_full;
    wire                          r_fifo_empty;
    wire                          r_fifo_rd_en;

    // Asynchronous FIFOs
    async_fifo #(
        .DATA_WIDTH(ADDR_WIDTH+3)
    ) aw_fifo (
        .clk_wr(s_clk),
        .rst_wr(s_rst),
        .din({s_axil_awaddr, s_axil_awprot, 1'b0}),
        .wr_en(s_axil_awvalid),
        .full(aw_fifo_full),
        .empty(aw_fifo_empty),
        .clk_rd(m_clk),
        .rst_rd(m_rst),
        .dout(aw_fifo_dout),
        .rd_en(aw_fifo_rd_en)
    );

    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH+STRB_WIDTH)
    ) w_fifo (
        .clk_wr(s_clk),
        .rst_wr(s_rst),
        .din({s_axil_wdata, s_axil_wstrb}),
        .wr_en(s_axil_wvalid),
        .full(w_fifo_full),
        .empty(w_fifo_empty),
        .clk_rd(m_clk),
        .rst_rd(m_rst),
        .dout(w_fifo_dout),
        .rd_en(w_fifo_rd_en)
    );

    async_fifo #(
        .DATA_WIDTH(ADDR_WIDTH+3)
    ) ar_fifo (
        .clk_wr(s_clk),
        .rst_wr(s_rst),
        .din({s_axil_araddr, s_axil_arprot, 1'b0}),
        .wr_en(s_axil_arvalid),
        .full(ar_fifo_full),
        .empty(ar_fifo_empty),
        .clk_rd(m_clk),
        .rst_rd(m_rst),
        .dout(ar_fifo_dout),
        .rd_en(ar_fifo_rd_en)
    );

    async_fifo #(
        .DATA_WIDTH(2)
    ) b_fifo (
        .clk_wr(m_clk),
        .rst_wr(m_rst),
        .din(m_axil_bresp),
        .wr_en(m_axil_bvalid),
        .full(b_fifo_full),
        .empty(b_fifo_empty),
        .clk_rd(s_clk),
        .rst_rd(s_rst),
        .dout(b_fifo_dout),
        .rd_en(b_fifo_rd_en)
    );

    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH+2)
    ) r_fifo (
        .clk_wr(m_clk),
        .rst_wr(m_rst),
        .din({m_axil_rdata, m_axil_rresp}),
        .wr_en(m_axil_rvalid),
        .full(r_fifo_full),
        .empty(r_fifo_empty),
        .clk_rd(s_clk),
        .rst_rd(s_rst),
        .dout(r_fifo_dout),
        .rd_en(r_fifo_rd_en)
    );

    // Assign master outputs
    assign m_axil_awaddr   = aw_fifo_dout[ADDR_WIDTH-1:0];
    assign m_axil_awprot   = aw_fifo_dout[ADDR_WIDTH+2:ADDR_WIDTH];
    assign m_axil_awvalid  = !aw_fifo_empty;
    assign aw_fifo_rd_en   = m_axil_awready;

    assign m_axil_wdata    = w_fifo_dout[DATA_WIDTH-1:0];
    assign m_axil_wstrb    = w_fifo_dout[DATA_WIDTH+STRB_WIDTH-1:DATA_WIDTH];
    assign m_axil_wvalid   = !w_fifo_empty;
    assign w_fifo_rd_en    = m_axil_wready;

    assign m_axil_araddr   = ar_fifo_dout[ADDR_WIDTH-1:0];
    assign m_axil_arprot   = ar_fifo_dout[ADDR_WIDTH+2:ADDR_WIDTH];
    assign m_axil_arvalid  = !ar_fifo_empty;
    assign ar_fifo_rd_en   = m_axil_arready;

    // Assign slave outputs
    assign s_axil_awready  = !aw_fifo_full;
    assign s_axil_wready   = !w_fifo_full;
    assign s_axil_arready  = !ar_fifo_full;

    assign s_axil_bresp    = b_fifo_dout;
    assign s_axil_bvalid   = !b_fifo_empty;
    assign b_fifo_rd_en    = s_axil_bready;

    assign s_axil_rdata    = r_fifo_dout[DATA_WIDTH-1:0];
    assign s_axil_rresp    = r_fifo_dout[DATA_WIDTH+1:DATA_WIDTH];
    assign s_axil_rvalid   = !r_fifo_empty;
    assign r_fifo_rd_en    = s_axil_rready;

    // Backpressure signals
    assign m_axil_bready   = 1'b1; // Always ready to accept B responses
    assign m_axil_rready   = 1'b1; // Always ready to accept R responses

endmodule

// Asynchronous FIFO module
module async_fifo #
(
    parameter DATA_WIDTH = 32
)
(
    input wire                  clk_wr,
    input wire                  rst_wr,
    input wire [DATA_WIDTH-1:0] din,
    input wire                  wr_en,
    output wire                 full,
    output wire                 empty,
    input wire                  clk_rd,
    input wire                  rst_rd,
    output wire [DATA_WIDTH-1:0] dout,
    input wire                  rd_en
);

    localparam DEPTH = 4;
    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;
    reg [ADDR_WIDTH:0]   wr_count;
    reg [ADDR_WIDTH:0]   rd_count;

    // Write pointer and count
    always @(posedge clk_wr or posedge rst_wr) begin
        if (rst_wr) begin
            wr_ptr <= 0;
            wr_count <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr] <= din;
            wr_ptr <= wr_ptr + 1;
            wr_count <= wr_count + 1;
        end
    end

    // Read pointer and count
    always @(posedge clk_rd or posedge rst_rd) begin
        if (rst_rd) begin
            rd_ptr <= 0;
            rd_count <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1;
            rd_count <= rd_count + 1;
        end
    end

    // Full flag
    assign full = (wr_count == DEPTH);

    // Empty flag
    assign empty = (wr_count == rd_count);

    // Data output
    reg [DATA_WIDTH-1:0] dout_reg;
    always @(posedge clk_rd or posedge rst_rd) begin
        if (rst_rd) begin
            dout_reg <= 0;
        end else if (rd_en && !empty) begin
            dout_reg <= mem[rd_ptr];
        end
    end

    assign dout = dout_reg;

endmodule
