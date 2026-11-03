module apb_cdc #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      src_pclk_i,
    input                      src_preset_ni,
    input                      src_psel_i,
    input                      src_penable_i,
    input                      src_pwrite_i,
    input  [ADDR_WIDTH-1:0]    src_paddr_i,
    input  [DATA_WIDTH-1:0]    src_pwdata_i,
    input  [DATA_WIDTH/8-1:0]  src_pstrb_i,
    input  [2:0]               src_pprot_i,
    output                     src_pready_o,
    output [DATA_WIDTH-1:0]    src_prdata_o,
    output                     src_pslverr_o,
    input                      dst_pclk_i,
    input                      dst_preset_ni,
    output                     dst_psel_o,
    output                     dst_penable_o,
    output                     dst_pwrite_o,
    output [ADDR_WIDTH-1:0]    dst_paddr_o,
    output [DATA_WIDTH-1:0]    dst_pwdata_o,
    output [DATA_WIDTH/8-1:0]  dst_pstrb_o,
    output [2:0]               dst_pprot_o,
    input                      dst_pready_i,
    input  [DATA_WIDTH-1:0]    dst_prdata_i,
    input                      dst_pslverr_i
);

    // Internal signals for FIFOs
    wire [ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+2:0] req_fifo_dout;
    wire [DATA_WIDTH:0] resp_fifo_dout;

    // Instantiate the request FIFO
    async_fifo #(
        .WIDTH(ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+3),
        .LOG_DEPTH(LOG_DEPTH)
    ) req_fifo (
        .clk_wr(src_pclk_i),
        .rst_wr(src_preset_ni),
        .wr_en(src_psel_i & src_penable_i),
        .din({src_pprot_i, src_pstrb_i, src_pwdata_i, src_paddr_i, src_pwrite_i}),
        .clk_rd(dst_pclk_i),
        .rst_rd(dst_preset_ni),
        .rd_en(dst_pready_i),
        .dout(req_fifo_dout)
    );

    // Instantiate the response FIFO
    async_fifo #(
        .WIDTH(DATA_WIDTH+1),
        .LOG_DEPTH(LOG_DEPTH)
    ) resp_fifo (
        .clk_wr(dst_pclk_i),
        .rst_wr(dst_preset_ni),
        .wr_en(dst_pready_i),
        .din({dst_pslverr_i, dst_prdata_i}),
        .clk_rd(src_pclk_i),
        .rst_rd(src_preset_ni),
        .rd_en(src_psel_i & src_penable_i),
        .dout(resp_fifo_dout)
    );

    // Assign outputs from FIFOs
    assign dst_pwrite_o   = req_fifo_dout[0];
    assign dst_paddr_o    = req_fifo_dout[ADDR_WIDTH:1];
    assign dst_pwdata_o   = req_fifo_dout[ADDR_WIDTH+DATA_WIDTH:ADDR_WIDTH];
    assign dst_pstrb_o    = req_fifo_dout[ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8-1:ADDR_WIDTH+DATA_WIDTH];
    assign dst_pprot_o    = req_fifo_dout[ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+2:ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8];
    assign dst_psel_o     = ~req_fifo.empty;
    assign dst_penable_o  = ~req_fifo.empty;

    assign src_prdata_o   = resp_fifo_dout[DATA_WIDTH-1:0];
    assign src_pslverr_o  = resp_fifo_dout[DATA_WIDTH];
    assign src_pready_o   = resp_fifo.empty;

endmodule

// Async FIFO module
module async_fifo #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 1
)(
    input                     clk_wr,
    input                     rst_wr,
    input                     wr_en,
    input  [WIDTH-1:0]      din,
    input                     clk_rd,
    input                     rst_rd,
    input                     rd_en,
    output [WIDTH-1:0]      dout
);

    localparam DEPTH = 1 << LOG_DEPTH;

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;
    reg [$clog2(DEPTH):0] wr_cnt, rd_cnt;

    // Write pointer and counter
    always @(posedge clk_wr or posedge rst_wr) begin
        if (rst_wr) begin
            wr_ptr <= 0;
            wr_cnt <= 0;
        end else if (wr_en && (wr_cnt != DEPTH)) begin
            mem[wr_ptr] <= din;
            wr_ptr <= wr_ptr + 1;
            wr_cnt <= wr_cnt + 1;
        end
    end

    // Read pointer and counter
    always @(posedge clk_rd or posedge rst_rd) begin
        if (rst_rd) begin
            rd_ptr <= 0;
            rd_cnt <= 0;
        end else if (rd_en && (rd_cnt != 0)) begin
            rd_ptr <= rd_ptr + 1;
            rd_cnt <= rd_cnt - 1;
        end
    end

    // Output data
    assign dout = mem[rd_ptr];

    // FIFO control signals
    assign full = (wr_cnt == DEPTH);
    assign empty = (wr_cnt == 0);

endmodule
