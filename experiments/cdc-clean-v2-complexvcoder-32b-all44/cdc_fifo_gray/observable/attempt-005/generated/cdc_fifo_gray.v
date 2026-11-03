module cdc_fifo_gray #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    // Internal signals
    wire [LOG_DEPTH:0] gray_src_count;
    wire [LOG_DEPTH:0] gray_dst_count;
    wire [LOG_DEPTH:0] sync_gray_src_count;
    wire [LOG_DEPTH:0] sync_gray_dst_count;
    wire [LOG_DEPTH-1:0] wr_ptr;
    wire [LOG_DEPTH-1:0] rd_ptr;
    wire                 empty;
    wire                 full;
    wire                 src_ready;
    wire                 dst_valid;

    // Gray code counters for source and destination
    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_src_counter (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .increment(src_valid_i & src_ready),
        .sync_signal(sync_gray_dst_count),
        .gray_count(gray_src_count),
        .bin_count(wr_ptr)
    );

    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_dst_counter (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .increment(dst_ready_i & dst_valid),
        .sync_signal(sync_gray_src_count),
        .gray_count(gray_dst_count),
        .bin_count(rd_ptr)
    );

    // Synchronization registers
    sync_register #(.WIDTH(LOG_DEPTH+1), .SYNC_STAGES(SYNC_STAGES)) sync_gray_src (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .data_i(gray_src_count),
        .data_o(sync_gray_src_count)
    );

    sync_register #(.WIDTH(LOG_DEPTH+1), .SYNC_STAGES(SYNC_STAGES)) sync_gray_dst (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .data_i(gray_dst_count),
        .data_o(sync_gray_dst_count)
    );

    // FIFO memory
    fifo_memory #(.WIDTH(WIDTH), .LOG_DEPTH(LOG_DEPTH)) fifo_mem (
        .rst_ni(src_rst_ni),
        .wr_clk_i(src_clk_i),
        .rd_clk_i(dst_clk_i),
        .data_in(src_data_i),
        .wr_ptr(wr_ptr),
        .rd_ptr(rd_ptr),
        .data_out(dst_data_o)
    );

    // FIFO control logic
    assign full = (gray_src_count[LOG_DEPTH-1:0] == gray_dst_count[LOG_DEPTH:1]) & (gray_src_count[LOG_DEPTH] != gray_dst_count[LOG_DEPTH]);
    assign empty = (gray_src_count == gray_dst_count);

    assign src_ready = ~full;
    assign dst_valid = ~empty;

    assign src_ready_o = src_ready;
    assign dst_valid_o = dst_valid;

endmodule

// Gray code counter module
module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  rst_ni,
    input                  clk_i,
    input                  increment,
    input  [LOG_DEPTH:0] sync_signal,
    output [LOG_DEPTH:0] gray_count,
    output [LOG_DEPTH-1:0] bin_count
);

    reg [LOG_DEPTH:0] count;
    reg [LOG_DEPTH:0] next_count;
    reg [LOG_DEPTH-1:0] bin_count_int;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            count <= 0;
        end else begin
            if (increment) begin
                count <= next_count;
            end
        end
    end

    assign next_count = (count + 1) ^ (count >> 1);
    assign bin_count_int = count[LOG_DEPTH-1:0];
    assign gray_count = count;
    assign bin_count = bin_count_int;

endmodule

// Synchronization register module
module sync_register #(
    parameter WIDTH = 4,
    parameter SYNC_STAGES = 2
)(
    input                  rst_ni,
    input                  clk_i,
    input  [WIDTH-1:0]     data_i,
    output [WIDTH-1:0]     data_o
);

    reg [WIDTH-1:0] sync_stage [SYNC_STAGES-1:0];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (int i = 0; i < SYNC_STAGES; i = i + 1) begin
                sync_stage[i] <= 0;
            end
        end else begin
            sync_stage[0] <= data_i;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_stage[i] <= sync_stage[i-1];
            end
        end
    end

    assign data_o = sync_stage[SYNC_STAGES-1];

endmodule

// FIFO memory module
module fifo_memory #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  rst_ni,
    input                  wr_clk_i,
    input                  rd_clk_i,
    input  [WIDTH-1:0]     data_in,
    input  [LOG_DEPTH-1:0] wr_ptr,
    input  [LOG_DEPTH-1:0] rd_ptr,
    output [WIDTH-1:0]     data_out
);

    reg [WIDTH-1:0] memory [0:(2**LOG_DEPTH)-1];

    always @(posedge wr_clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (int i = 0; i < (2**LOG_DEPTH); i = i + 1) begin
                memory[i] <= 0;
            end
        end else begin
            memory[wr_ptr] <= data_in;
        end
    end

    always @(posedge rd_clk_i) begin
        data_out <= memory[rd_ptr];
    end

endmodule
