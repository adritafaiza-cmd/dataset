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

    localparam DEPTH = 2**LOG_DEPTH;
    localparam ADDR_WIDTH = LOG_DEPTH;

    // Source side signals
    reg [ADDR_WIDTH:0] src_wr_ptr_gray;
    reg [ADDR_WIDTH:0] src_wr_ptr_gray_nxt;
    reg [ADDR_WIDTH:0] src_rd_ptr_gray_sync;
    reg [WIDTH-1:0]    mem [DEPTH-1:0];

    // Destination side signals
    reg [ADDR_WIDTH:0] dst_rd_ptr_gray;
    reg [ADDR_WIDTH:0] dst_rd_ptr_gray_nxt;
    reg [ADDR_WIDTH:0] dst_wr_ptr_gray_sync;

    // Binary conversion
    function [ADDR_WIDTH:0] bin_to_gray;
        input [ADDR_WIDTH:0] bin;
        bin_to_gray = bin ^ (bin >> 1);
    endfunction

    function [ADDR_WIDTH:0] gray_to_bin;
        input [ADDR_WIDTH:0] gray;
        integer i;
        reg [ADDR_WIDTH:0] bin;
        bin = gray;
        for (i = ADDR_WIDTH; i > 0; i = i - 1) begin
            bin[i-1] = bin[i] ^ bin[i-1];
        end
        gray_to_bin = bin;
    endfunction

    // Source side logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr_gray <= 0;
        end else begin
            src_wr_ptr_gray <= src_wr_ptr_gray_nxt;
        end
    end

    always @(*) begin
        src_wr_ptr_gray_nxt = src_wr_ptr_gray;
        if (src_valid_i && src_ready_o) begin
            src_wr_ptr_gray_nxt = bin_to_gray(gray_to_bin(src_wr_ptr_gray) + 1);
        end
    end

    // Destination side logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr_gray <= 0;
        end else begin
            dst_rd_ptr_gray <= dst_rd_ptr_gray_nxt;
        end
    end

    always @(*) begin
        dst_rd_ptr_gray_nxt = dst_rd_ptr_gray;
        if (dst_valid_o && dst_ready_i) begin
            dst_rd_ptr_gray_nxt = bin_to_gray(gray_to_bin(dst_rd_ptr_gray) + 1);
        end
    end

    // Cross-domain synchronization for read pointers
    reg [SYNC_STAGES-1:0][ADDR_WIDTH:0] src_rd_ptr_gray_sync_pipeline;
    reg [SYNC_STAGES-1:0][ADDR_WIDTH:0] dst_wr_ptr_gray_sync_pipeline;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_rd_ptr_gray_sync_pipeline <= {SYNC_STAGES{0}};
        end else begin
            src_rd_ptr_gray_sync_pipeline[0] <= dst_rd_ptr_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                src_rd_ptr_gray_sync_pipeline[i] <= src_rd_ptr_gray_sync_pipeline[i-1];
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_ptr_gray_sync_pipeline <= {SYNC_STAGES{0}};
        end else begin
            dst_wr_ptr_gray_sync_pipeline[0] <= src_wr_ptr_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                dst_wr_ptr_gray_sync_pipeline[i] <= dst_wr_ptr_gray_sync_pipeline[i-1];
            end
        end
    end

    assign src_rd_ptr_gray_sync = src_rd_ptr_gray_sync_pipeline[SYNC_STAGES-1];
    assign dst_wr_ptr_gray_sync = dst_wr_ptr_gray_sync_pipeline[SYNC_STAGES-1];

    // Source ready and destination valid
    assign src_ready_o = (gray_to_bin(src_wr_ptr_gray) + 1) != gray_to_bin(src_rd_ptr_gray_sync);
    assign dst_valid_o = (gray_to_bin(dst_wr_ptr_gray_sync) != gray_to_bin(dst_rd_ptr_gray));

    // Memory write
    always @(posedge src_clk_i) begin
        if (src_valid_i && src_ready_o) begin
            mem[gray_to_bin(src_wr_ptr_gray)[ADDR_WIDTH-1:0]] <= src_data_i;
        end
    end

    // Memory read
    always @(posedge dst_clk_i) begin
        if (dst_valid_o && dst_ready_i) begin
            dst_data_o <= mem[gray_to_bin(dst_rd_ptr_gray)[ADDR_WIDTH-1:0]];
        end
    end

endmodule
