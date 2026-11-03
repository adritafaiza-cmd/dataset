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
    logic [WIDTH-1:0]       mem [0:(1<<LOG_DEPTH)-1];
    logic [LOG_DEPTH:0]     src_wr_ptr, src_rd_ptr;
    logic [LOG_DEPTH:0]     dst_rd_ptr;
    logic [LOG_DEPTH:0]     src_wr_ptr_gray, src_rd_ptr_gray, dst_rd_ptr_gray;
    logic                   src_fifo_not_empty, src_fifo_not_full;
    logic                   dst_fifo_not_empty, dst_fifo_not_full;
    logic [SYNC_STAGES-1:0] sync_src_valid, sync_dst_ready;

    // Gray coding helper functions
    function [LOG_DEPTH:0] gray_encode;
        input [LOG_DEPTH:0] dec;
        begin
            gray_encode = dec ^ (dec >> 1);
        end
    endfunction

    function [LOG_DEPTH:0] gray_decode;
        input [LOG_DEPTH:0] gray;
        integer i;
        begin
            gray_decode = gray;
            for (i = LOG_DEPTH-1; i > 0; i = i - 1) begin
                gray_decode = gray_decode ^ (gray_decode >> i);
            end
        end
    endfunction

    // Write pointer logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= 0;
        end else begin
            if (src_valid_i && src_ready_o && !src_fifo_not_full) begin
                src_wr_ptr <= src_wr_ptr + 1;
            end
        end
    end

    // Read pointer logic
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= 0;
        end else begin
            if (dst_ready_i && dst_valid_o && !dst_fifo_not_empty) begin
                dst_rd_ptr <= dst_rd_ptr + 1;
            end
        end
    end

    // FIFO not empty/full flags
    assign src_fifo_not_empty = (src_wr_ptr_gray != src_rd_ptr_gray);
    assign src_fifo_not_full = (src_wr_ptr_gray != (src_rd_ptr_gray + 1));
    assign dst_fifo_not_empty = (dst_rd_ptr_gray != src_rd_ptr_gray);
    assign dst_fifo_not_full = (dst_rd_ptr_gray != (src_rd_ptr_gray + 1));

    // Gray coding of pointers
    assign src_wr_ptr_gray = gray_encode(src_wr_ptr);
    assign src_rd_ptr_gray = gray_encode(src_rd_ptr);
    assign dst_rd_ptr_gray = gray_encode(dst_rd_ptr);

    // Source ready logic
    assign src_ready_o = src_fifo_not_full;

    // Destination data and valid logic
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_o <= 0;
            dst_valid_o <= 0;
        end else begin
            if (dst_ready_i && dst_valid_o) begin
                dst_data_o <= mem[gray_decode(dst_rd_ptr)];
                dst_valid_o <= 1;
            end else begin
                dst_valid_o <= 0;
            end
        end
    end

    // Synchronization for valid and ready signals
    sync_ff #(WIDTH) sync_src_valid_ff (
        .clk(src_clk_i),
        .rst_n(src_rst_ni),
        .d(src_valid_i),
        .q(sync_src_valid)
    );

    sync_ff #(WIDTH) sync_dst_ready_ff (
        .clk(dst_clk_i),
        .rst_n(dst_rst_ni),
        .d(dst_ready_i),
        .q(sync_dst_ready)
    );

    // Destination ready logic
    assign dst_ready_o = sync_src_valid & sync_dst_ready & !dst_fifo_not_empty;

endmodule

module sync_ff #(
    parameter WIDTH = 8
)(
    input  clk,
    input  rst_n,
    input  [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 0;
        end else begin
            q <= d;
        end
    end

endmodule
