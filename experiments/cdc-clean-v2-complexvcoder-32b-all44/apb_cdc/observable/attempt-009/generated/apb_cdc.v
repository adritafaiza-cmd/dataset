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
    wire                       req_fifo_push;
    wire                       req_fifo_pop;
    wire [3 + ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 3 - 1:0] req_fifo_dout;
    wire                       req_fifo_empty;

    wire                       resp_fifo_push;
    wire                       resp_fifo_pop;
    wire [DATA_WIDTH + 1 - 1:0] resp_fifo_dout;
    wire                       resp_fifo_empty;

    // Instantiate FIFOs
    fifo_sync #(
        .DATA_WIDTH(3 + ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 3),
        .LOG_DEPTH(LOG_DEPTH)
    ) req_fifo (
        .clk_wr(src_pclk_i),
        .rst_wr_ni(src_preset_ni),
        .din({src_psel_i, src_penable_i, src_pwrite_i, src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i}),
        .wr_en(req_fifo_push),
        .clk_rd(dst_pclk_i),
        .rst_rd_ni(dst_preset_ni),
        .dout(req_fifo_dout),
        .empty(req_fifo_empty),
        .rd_en(req_fifo_pop)
    );

    fifo_sync #(
        .DATA_WIDTH(DATA_WIDTH + 1),
        .LOG_DEPTH(LOG_DEPTH)
    ) resp_fifo (
        .clk_wr(dst_pclk_i),
        .rst_wr_ni(dst_preset_ni),
        .din({dst_prdata_i, dst_pslverr_i}),
        .wr_en(resp_fifo_push),
        .clk_rd(src_pclk_i),
        .rst_rd_ni(src_preset_ni),
        .dout(resp_fifo_dout),
        .empty(resp_fifo_empty),
        .rd_en(resp_fifo_pop)
    );

    // FIFO control signals
    assign req_fifo_push = src_psel_i & src_penable_i;
    assign req_fifo_pop = !req_fifo_empty & dst_pready_i;

    assign resp_fifo_push = dst_pready_i;
    assign resp_fifo_pop = !resp_fifo_empty & src_penable_i;

    // Destination side APB signals
    assign dst_psel_o = !req_fifo_empty;
    assign dst_penable_o = !req_fifo_empty & dst_pready_i;
    assign dst_pwrite_o = req_fifo_dout[2];
    assign dst_paddr_o = req_fifo_dout[3 +: ADDR_WIDTH];
    assign dst_pwdata_o = req_fifo_dout[3 + ADDR_WIDTH +: DATA_WIDTH];
    assign dst_pstrb_o = req_fifo_dout[3 + ADDR_WIDTH + DATA_WIDTH +: DATA_WIDTH/8];
    assign dst_pprot_o = req_fifo_dout[3 + ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 +: 3];

    // Source side APB signals
    assign src_prdata_o = resp_fifo_dout[0 +: DATA_WIDTH];
    assign src_pslverr_o = resp_fifo_dout[DATA_WIDTH];
    assign src_pready_o = resp_fifo_empty | (src_penable_i & !resp_fifo_empty);

endmodule

// FIFO synchronization module
module fifo_sync #(
    parameter DATA_WIDTH = 0,
    parameter LOG_DEPTH = 0
)(
    input                      clk_wr,
    input                      rst_wr_ni,
    input  [DATA_WIDTH-1:0]    din,
    input                      wr_en,
    input                      clk_rd,
    input                      rst_rd_ni,
    output [DATA_WIDTH-1:0]    dout,
    output                     empty,
    input                      rd_en
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam ADDR_WIDTH = LOG_DEPTH;

    reg [DATA_WIDTH-1:0] mem [DEPTH-1:0];
    reg [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
    reg [ADDR_WIDTH:0] count;

    always @(posedge clk_wr or negedge rst_wr_ni) begin
        if (!rst_wr_ni) begin
            wr_ptr <= 0;
            count <= 0;
        end else if (wr_en && (count != DEPTH)) begin
            mem[wr_ptr] <= din;
            wr_ptr <= wr_ptr + 1;
            count <= count + 1;
        end
    end

    always @(posedge clk_rd or negedge rst_rd_ni) begin
        if (!rst_rd_ni) begin
            rd_ptr <= 0;
            count <= 0;
        end else if (rd_en && (count != 0)) begin
            rd_ptr <= rd_ptr + 1;
            count <= count - 1;
        end
    end

    assign dout = mem[rd_ptr];
    assign empty = (count == 0);

endmodule
