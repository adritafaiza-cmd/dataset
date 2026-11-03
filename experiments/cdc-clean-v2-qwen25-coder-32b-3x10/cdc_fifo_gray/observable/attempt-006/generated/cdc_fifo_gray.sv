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

    reg [WIDTH-1:0] mem [DEPTH-1:0];

    // Source side pointers
    reg [ADDR_WIDTH:0] src_wr_ptr;
    reg [ADDR_WIDTH:0] src_wr_ptr_gray;
    reg [ADDR_WIDTH:0] src_rd_ptr_gray_sync;

    // Destination side pointers
    reg [ADDR_WIDTH:0] dst_rd_ptr;
    reg [ADDR_WIDTH:0] dst_rd_ptr_gray;
    reg [ADDR_WIDTH:0] dst_wr_ptr_gray_sync;

    // Gray code conversion functions
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
            src_wr_ptr <= 0;
            src_wr_ptr_gray <= 0;
        end else begin
            if (src_valid_i && src_ready_o) begin
                mem[src_wr_ptr[ADDR_WIDTH-1:0]] <= src_data_i;
                src_wr_ptr <= src_wr_ptr + 1;
                src_wr_ptr_gray <= bin_to_gray(src_wr_ptr + 1);
            end
        end
    end

    // Synchronize src_wr_ptr_gray to destination clock domain
    reg [ADDR_WIDTH:0] src_wr_ptr_gray_sync [SYNC_STAGES-1:0];
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_wr_ptr_gray_sync <= {SYNC_STAGES{ADDR_WIDTH+1{1'b0}}};
        end else begin
            src_wr_ptr_gray_sync[0] <= src_wr_ptr_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                src_wr_ptr_gray_sync[i] <= src_wr_ptr_gray_sync[i-1];
            end
        end
    end

    // Destination side logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= 0;
            dst_rd_ptr_gray <= 0;
        end else begin
            if (dst_valid_o && dst_ready_i) begin
                dst_rd_ptr <= dst_rd_ptr + 1;
                dst_rd_ptr_gray <= bin_to_gray(dst_rd_ptr + 1);
            end
        end
    end

    // Synchronize dst_rd_ptr_gray to source clock domain
    reg [ADDR_WIDTH:0] dst_rd_ptr_gray_sync [SYNC_STAGES-1:0];
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_rd_ptr_gray_sync <= {SYNC_STAGES{ADDR_WIDTH+1{1'b0}}};
        end else begin
            dst_rd_ptr_gray_sync[0] <= dst_rd_ptr_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                dst_rd_ptr_gray_sync[i] <= dst_rd_ptr_gray_sync[i-1];
            end
        end
    end

    // Calculate src_ready_o
    assign src_ready_o = (gray_to_bin(src_wr_ptr_gray) != gray_to_bin(src_wr_ptr_gray_sync[SYNC_STAGES-1]));

    // Calculate dst_valid_o
    assign dst_valid_o = (gray_to_bin(dst_wr_ptr_gray_sync[SYNC_STAGES-1]) != gray_to_bin(dst_rd_ptr_gray));

    // Output data
    assign dst_data_o = mem[dst_rd_ptr[ADDR_WIDTH-1:0]];

endmodule
