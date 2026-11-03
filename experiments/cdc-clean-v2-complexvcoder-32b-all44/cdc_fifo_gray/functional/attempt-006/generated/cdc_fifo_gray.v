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

    localparam DEPTH = 1 << LOG_DEPTH;

    // Internal signals
    reg [LOG_DEPTH:0]      src_wr_ptr_gray, src_wr_ptr_bin;
    reg [LOG_DEPTH:0]      src_rd_ptr_gray_sync, src_rd_ptr_bin_sync;
    reg [LOG_DEPTH:0]      dst_wr_ptr_gray_sync, dst_wr_ptr_bin_sync;
    reg [LOG_DEPTH:0]      dst_rd_ptr_gray, dst_rd_ptr_bin;
    reg                    src_wr_en, dst_rd_en;
    reg                    fifo_full, fifo_empty;
    reg [WIDTH-1:0]        fifo_mem [0:DEPTH-1];

    // Gray counter for source write pointer
    gray_counter #(.LOG_DEPTH(LOG_DEPTH))
    src_gray_counter (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .ptr_gray_o(src_wr_ptr_gray),
        .ptr_bin_o(src_wr_ptr_bin)
    );

    // Gray counter for destination read pointer
    gray_counter #(.LOG_DEPTH(LOG_DEPTH))
    dst_gray_counter (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .ptr_gray_o(dst_rd_ptr_gray),
        .ptr_bin_o(dst_rd_ptr_bin)
    );

    // Synchronize source write pointer to destination domain
    sync_stage #(.WIDTH(LOG_DEPTH+1), .STAGES(SYNC_STAGES))
    sync_wr_ptr_gray (
        .clk_i(dst_clk_i),
        .src_ptr_i(src_wr_ptr_gray),
        .dst_ptr_o(dst_wr_ptr_gray_sync)
    );

    // Synchronize destination read pointer to source domain
    sync_stage #(.WIDTH(LOG_DEPTH+1), .STAGES(SYNC_STAGES))
    sync_rd_ptr_gray (
        .clk_i(src_clk_i),
        .src_ptr_i(dst_rd_ptr_gray),
        .dst_ptr_o(src_rd_ptr_gray_sync)
    );

    // FIFO full and empty conditions
    assign fifo_full = (src_wr_ptr_bin == {1'b1, dst_wr_ptr_bin_sync[LOG_DEPTH-1:0]});
    assign fifo_empty = (dst_rd_ptr_bin == src_rd_ptr_bin_sync);

    // Source ready and destination valid signals
    assign src_ready_o = ~fifo_full;
    assign dst_valid_o = ~fifo_empty;

    // Write enable and read enable signals
    assign src_wr_en = src_valid_i & src_ready_o;
    assign dst_rd_en = dst_ready_i & dst_valid_o;

    // FIFO memory write operation
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            fifo_mem <= '{default: 0};
        end else if (src_wr_en) begin
            fifo_mem[src_wr_ptr_bin[LOG_DEPTH-1:0]] <= src_data_i;
        end
    end

    // FIFO memory read operation
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_o <= 0;
        end else if (dst_rd_en) begin
            dst_data_o <= fifo_mem[dst_rd_ptr_bin[LOG_DEPTH-1:0]];
        end
    end

endmodule

// Gray counter module
module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  rst_ni,
    input                  clk_i,
    output reg [LOG_DEPTH:0] ptr_gray_o,
    output reg [LOG_DEPTH:0] ptr_bin_o
);

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            ptr_bin_o <= 0;
            ptr_gray_o <= 0;
        end else begin
            ptr_bin_o <= ptr_bin_o + 1;
            ptr_gray_o <= (ptr_bin_o >> 1) ^ ptr_bin_o;
        end
    end

endmodule

// Synchronization stage module
module sync_stage #(
    parameter WIDTH = 5,
    parameter STAGES = 2
)(
    input                  clk_i,
    input  [WIDTH-1:0]     src_ptr_i,
    output reg [WIDTH-1:0] dst_ptr_o
);

    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : sync_stages
            if (i == 0) begin
                always @(posedge clk_i) begin
                    dst_ptr_o <= src_ptr_i;
                end
            end else begin
                always @(posedge clk_i) begin
                    dst_ptr_o <= dst_ptr_o;
                end
            end
        end
    endgenerate

endmodule
