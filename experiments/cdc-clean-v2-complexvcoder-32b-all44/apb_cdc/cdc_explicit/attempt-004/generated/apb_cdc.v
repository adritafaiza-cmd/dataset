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

    // Internal signals
    wire [ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+5:0] request_fifo_dout;
    wire request_fifo_empty;
    wire [DATA_WIDTH:0] response_fifo_dout;
    wire response_fifo_empty;
    wire response_fifo_full_n;

    // Instantiate async FIFO for requests
    async_fifo #(
        .WIDTH(ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+6),
        .LOG_DEPTH(LOG_DEPTH)
    ) request_fifo_inst (
        .clk_wr(src_pclk_i),
        .rst_wr(~src_preset_ni),
        .din({src_pprot_i, src_pstrb_i, src_pwdata_i, src_paddr_i, src_pwrite_i, src_penable_i, src_psel_i}),
        .full_n(src_pready_o),
        .clk_rd(dst_pclk_i),
        .rst_rd(~dst_preset_ni),
        .dout(request_fifo_dout),
        .empty(request_fifo_empty)
    );

    // Instantiate async FIFO for responses
    async_fifo #(
        .WIDTH(DATA_WIDTH+1),
        .LOG_DEPTH(LOG_DEPTH)
    ) response_fifo_inst (
        .clk_wr(dst_pclk_i),
        .rst_wr(~dst_preset_ni),
        .din({dst_pslverr_i, dst_prdata_i}),
        .full_n(response_fifo_full_n),
        .clk_rd(src_pclk_i),
        .rst_rd(~src_preset_ni),
        .dout(response_fifo_dout),
        .empty(response_fifo_empty)
    );

    // Assign output signals from request FIFO
    assign dst_psel_o     = request_fifo_dout[0];
    assign dst_penable_o  = request_fifo_dout[1];
    assign dst_pwrite_o   = request_fifo_dout[2];
    assign dst_paddr_o    = request_fifo_dout[ADDR_WIDTH+2:3];
    assign dst_pwdata_o   = request_fifo_dout[ADDR_WIDTH+DATA_WIDTH+2:ADDR_WIDTH+3];
    assign dst_pstrb_o    = request_fifo_dout[ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+2:ADDR_WIDTH+DATA_WIDTH+3];
    assign dst_pprot_o    = request_fifo_dout[ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+5:ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+3];

    // Assign output signals from response FIFO
    assign src_prdata_o   = response_fifo_dout[DATA_WIDTH-1:0];
    assign src_pslverr_o  = response_fifo_dout[DATA_WIDTH];

endmodule

module async_fifo #(
    parameter WIDTH = 38,
    parameter LOG_DEPTH = 1
)(
    input                      clk_wr,
    input                      rst_wr,
    input  [WIDTH-1:0]       din,
    output                     full_n,
    input                      clk_rd,
    input                      rst_rd,
    output [WIDTH-1:0]       dout,
    output                     empty
);

    // Internal signals
    reg  [LOG_DEPTH:0]       wr_ptr;
    reg  [LOG_DEPTH:0]       rd_ptr;
    reg  [LOG_DEPTH:0]       wr_ptr_gray;
    reg  [LOG_DEPTH:0]       rd_ptr_gray;
    reg  [LOG_DEPTH:0]       wr_ptr_gray_synced;
    reg  [LOG_DEPTH:0]       rd_ptr_gray_synced;
    reg  [WIDTH-1:0]         mem [0:(1<<LOG_DEPTH)-1];

    // Write pointer logic
    always @(posedge clk_wr or posedge rst_wr) begin
        if (rst_wr) begin
            wr_ptr <= 0;
        end else if (~full_n) begin
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Gray code conversion for write pointer
    assign wr_ptr_gray = (wr_ptr >> 1) ^ wr_ptr;

    // Gray code conversion for read pointer
    assign rd_ptr_gray = (rd_ptr >> 1) ^ rd_ptr;

    // Synchronize write pointer gray code to read clock domain
    always @(posedge clk_rd or posedge rst_rd) begin
        if (rst_rd) begin
            wr_ptr_gray_synced <= 0;
        end else begin
            wr_ptr_gray_synced <= wr_ptr_gray;
        end
    end

    // Synchronize read pointer gray code to write clock domain
    always @(posedge clk_wr or posedge rst_wr) begin
        if (rst_wr) begin
            rd_ptr_gray_synced <= 0;
        end else begin
            rd_ptr_gray_synced <= rd_ptr_gray;
        end
    end

    // Memory write logic
    always @(posedge clk_wr) begin
        if (~full_n) begin
            mem[wr_ptr[LOG_DEPTH-1:0]] <= din;
        end
    end

    // Memory read logic
    always @(posedge clk_rd) begin
        if (~empty) begin
            dout <= mem[rd_ptr[LOG_DEPTH-1:0]];
        end
    end

    // Full flag logic
    assign full_n = (wr_ptr_gray_synced != (rd_ptr_gray + 1));

    // Empty flag logic
    assign empty = (wr_ptr_gray == rd_ptr_gray_synced);

endmodule
