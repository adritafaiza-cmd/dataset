module cdc_fifo_2phase #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
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
    reg  [LOG_DEPTH-1:0] wr_ptr, rd_ptr;
    reg  [LOG_DEPTH-1:0] wr_ptr_gray, rd_ptr_gray;
    reg  [LOG_DEPTH-1:0] wr_ptr_gray_synced, rd_ptr_gray_synced;
    reg  [WIDTH-1:0]     fifo_mem [0:(1<<LOG_DEPTH)-1];
    reg  [WIDTH-1:0]     dst_data_stage1, dst_data_stage2;
    reg                  dst_valid_stage1, dst_valid_stage2;
    wire                 full, empty;

    // Gray code conversion functions
    function [LOG_DEPTH-1:0] bin2gray;
        input [LOG_DEPTH-1:0] bin;
        bin2gray = bin ^ (bin >> 1);
    endfunction

    function [LOG_DEPTH-1:0] gray2bin;
        input [LOG_DEPTH-1:0] gray;
        integer i;
        reg [LOG_DEPTH-1:0] bin;
        bin = gray;
        for (i = LOG_DEPTH - 2; i >= 0; i = i - 1) begin
            bin[i] = bin[i+1] ^ gray[i];
        end
        gray2bin = bin;
    endfunction

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (src_valid_i && src_ready_o) begin
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= bin2gray(wr_ptr + 1);
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
            dst_data_stage1 <= 0;
            dst_data_stage2 <= 0;
            dst_valid_stage1 <= 0;
            dst_valid_stage2 <= 0;
        end else begin
            // Stage 1: Capture data from FIFO
            if (!empty && dst_ready_i && dst_valid_stage2) begin
                rd_ptr <= rd_ptr + 1;
                rd_ptr_gray <= bin2gray(rd_ptr + 1);
            end
            // Stage 2: Pipeline stage 1 to stage 2
            dst_data_stage1 <= fifo_mem[gray2bin(wr_ptr_gray_synced)];
            dst_valid_stage1 <= (wr_ptr_gray_synced != rd_ptr_gray);
            // Stage 3: Pipeline stage 2 to output
            dst_data_stage2 <= dst_data_stage1;
            dst_valid_stage2 <= dst_valid_stage1;
        end
    end

    // Synchronization of write pointer to destination domain
    sync_register #(.LOG_DEPTH(LOG_DEPTH)) sync_wr_ptr (
        .d(wr_ptr_gray),
        .q(wr_ptr_gray_synced),
        .src_clk_i(src_clk_i),
        .src_rst_ni(src_rst_ni),
        .dst_clk_i(dst_clk_i),
        .dst_rst_ni(dst_rst_ni)
    );

    // Synchronization of read pointer to source domain
    sync_register #(.LOG_DEPTH(LOG_DEPTH)) sync_rd_ptr (
        .d(rd_ptr_gray),
        .q(rd_ptr_gray_synced),
        .src_clk_i(dst_clk_i),
        .src_rst_ni(dst_rst_ni),
        .dst_clk_i(src_clk_i),
        .dst_rst_ni(src_rst_ni)
    );

    // Full and empty flags
    assign full = (wr_ptr_gray == bin2gray(rd_ptr_gray_synced + (1<<LOG_DEPTH)));
    assign empty = (wr_ptr_gray_synced == rd_ptr_gray);

    // Ready and valid signals
    assign src_ready_o = !full;
    assign dst_data_o = dst_data_stage2;
    assign dst_valid_o = dst_valid_stage2;

endmodule

module sync_register #(
    parameter LOG_DEPTH = 3
)(
    input  [LOG_DEPTH-1:0] d,
    output [LOG_DEPTH-1:0] q,
    input                  src_clk_i,
    input                  src_rst_ni,
    input                  dst_clk_i,
    input                  dst_rst_ni
);

    reg [LOG_DEPTH-1:0] q1, q2;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            q1 <= 0;
        end else begin
            q1 <= d;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            q2 <= 0;
        end else begin
            q2 <= q1;
        end
    end

    assign q = q2;

endmodule
