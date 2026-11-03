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
    wire [ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 3 + 1 - 1:0] request_fifo_dout;
    wire                                                     request_fifo_empty;
    wire [DATA_WIDTH + 1 - 1:0]                             response_fifo_dout;
    wire                                                     response_fifo_empty;

    // Instantiate request FIFO
    async_fifo #(
        .WIDTH(ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 3 + 1),
        .LOG_DEPTH(LOG_DEPTH)
    ) request_fifo (
        .clk_wr(src_pclk_i),
        .rst_wr(~src_preset_ni),
        .wr_en(src_psel_i & src_penable_i),
        .din({src_pwrite_i, src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i}),
        .clk_rd(dst_pclk_i),
        .rst_rd(~dst_preset_ni),
        .rd_en(dst_pready_i),
        .dout(request_fifo_dout),
        .empty(request_fifo_empty)
    );

    // Instantiate response FIFO
    async_fifo #(
        .WIDTH(DATA_WIDTH + 1),
        .LOG_DEPTH(LOG_DEPTH)
    ) response_fifo (
        .clk_wr(dst_pclk_i),
        .rst_wr(~dst_preset_ni),
        .wr_en(dst_pready_i),
        .din({dst_prdata_i, dst_pslverr_i}),
        .clk_rd(src_pclk_i),
        .rst_rd(~src_preset_ni),
        .rd_en(src_pready_o),
        .dout(response_fifo_dout),
        .empty(response_fifo_empty)
    );

    // Assign outputs from FIFOs
    assign {dst_pwrite_o, dst_paddr_o, dst_pwdata_o, dst_pstrb_o, dst_pprot_o} = request_fifo_dout;
    assign {src_prdata_o, src_pslverr_o} = response_fifo_dout;

    // Control signals
    assign dst_psel_o = ~request_fifo_empty;
    assign dst_penable_o = ~request_fifo_empty;
    assign src_pready_o = ~response_fifo_empty & dst_pready_i;

endmodule

// Asynchronous FIFO module
module async_fifo #(
    parameter WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      clk_wr,
    input                      rst_wr,
    input                      wr_en,
    input  [WIDTH-1:0]         din,
    input                      clk_rd,
    input                      rst_rd,
    input                      rd_en,
    output [WIDTH-1:0]         dout,
    output                     empty
);

    localparam DEPTH = 1 << LOG_DEPTH;

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH):0] wr_ptr, rd_ptr;
    reg [$clog2(DEPTH):0] wr_ptr_gray, rd_ptr_gray;
    reg [$clog2(DEPTH):0] wr_ptr_gray_sync, rd_ptr_gray_sync;

    // Write pointer logic
    always @(posedge clk_wr or negedge rst_wr) begin
        if (!rst_wr)
            wr_ptr <= 0;
        else if (wr_en && !(wr_ptr_gray_sync == rd_ptr_gray && wr_ptr_gray[$clog2(DEPTH)] != rd_ptr_gray[$clog2(DEPTH)]))
            wr_ptr <= wr_ptr + 1;
    end

    // Read pointer logic
    always @(posedge clk_rd or negedge rst_rd) begin
        if (!rst_rd)
            rd_ptr <= 0;
        else if (rd_en && !(wr_ptr_gray == rd_ptr_gray_sync && wr_ptr_gray[$clog2(DEPTH)] != rd_ptr_gray_sync[$clog2(DEPTH)]))
            rd_ptr <= rd_ptr + 1;
    end

    // Binary to Gray conversion
    assign wr_ptr_gray = wr_ptr ^ (wr_ptr >> 1);
    assign rd_ptr_gray = rd_ptr ^ (rd_ptr >> 1);

    // Gray to binary conversion and synchronization
    sync_gray_counter #(
        .WIDTH($clog2(DEPTH)+1)
    ) sync_wr_ptr (
        .clk(clk_rd),
        .rst(~rst_rd),
        .din(wr_ptr_gray),
        .dout(wr_ptr_gray_sync)
    );

    sync_gray_counter #(
        .WIDTH($clog2(DEPTH)+1)
    ) sync_rd_ptr (
        .clk(clk_wr),
        .rst(~rst_wr),
        .din(rd_ptr_gray),
        .dout(rd_ptr_gray_sync)
    );

    // Memory write
    always @(posedge clk_wr) begin
        if (wr_en && !(wr_ptr_gray_sync == rd_ptr_gray && wr_ptr_gray[$clog2(DEPTH)] != rd_ptr_gray[$clog2(DEPTH)]))
            mem[wr_ptr[$clog2(DEPTH)-1:0]] <= din;
    end

    // Memory read
    always @(posedge clk_rd) begin
        if (rd_en && !(wr_ptr_gray == rd_ptr_gray_sync && wr_ptr_gray[$clog2(DEPTH)] != rd_ptr_gray_sync[$clog2(DEPTH)]))
            dout <= mem[rd_ptr[$clog2(DEPTH)-1:0]];
    end

    // Empty flag
    assign empty = wr_ptr_gray_sync == rd_ptr_gray;

endmodule

// Synchronizer for Gray counter
module sync_gray_counter #(
    parameter WIDTH = 3
)(
    input                      clk,
    input                      rst,
    input  [WIDTH-1:0]         din,
    output [WIDTH-1:0]         dout
);

    reg [WIDTH-1:0] stage1, stage2;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            stage1 <= 0;
            stage2 <= 0;
        end else begin
            stage1 <= din;
            stage2 <= stage1;
        end
    end

    assign dout = stage2;

endmodule
