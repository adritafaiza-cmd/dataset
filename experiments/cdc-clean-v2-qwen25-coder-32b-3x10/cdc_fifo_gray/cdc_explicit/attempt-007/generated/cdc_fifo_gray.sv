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
    localparam ADDR_WIDTH = LOG_DEPTH;

    // Source domain signals
    reg [ADDR_WIDTH:0] src_wr_ptr_gray;
    reg [ADDR_WIDTH:0] src_wr_ptr_gray_nxt;
    reg [ADDR_WIDTH:0] src_rd_ptr_gray_sync;
    reg [WIDTH-1:0]    mem [DEPTH-1:0];

    // Destination domain signals
    reg [ADDR_WIDTH:0] dst_rd_ptr_gray;
    reg [ADDR_WIDTH:0] dst_rd_ptr_gray_nxt;
    reg [ADDR_WIDTH:0] dst_wr_ptr_gray_sync;
    reg [WIDTH-1:0]    dst_data_sync [SYNC_STAGES-1:0];
    reg                dst_valid_sync [SYNC_STAGES-1:0];

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

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr_gray <= 0;
            src_wr_ptr_gray_nxt <= 0;
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

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_rd_ptr_gray_sync <= 0;
        end else begin
            src_rd_ptr_gray_sync <= dst_rd_ptr_gray;
        end
    end

    assign src_ready_o = (gray_to_bin(src_wr_ptr_gray) != gray_to_bin(src_rd_ptr_gray_sync));

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            mem[gray_to_bin(src_wr_ptr_gray)] <= 0;
        end else if (src_valid_i && src_ready_o) begin
            mem[gray_to_bin(src_wr_ptr_gray)] <= src_data_i;
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr_gray <= 0;
            dst_rd_ptr_gray_nxt <= 0;
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

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_ptr_gray_sync <= 0;
        end else begin
            dst_wr_ptr_gray_sync <= src_wr_ptr_gray;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_sync[0] <= 0;
            dst_valid_sync[0] <= 0;
        end else begin
            if (gray_to_bin(dst_wr_ptr_gray_sync) != gray_to_bin(dst_rd_ptr_gray)) begin
                dst_data_sync[0] <= mem[gray_to_bin(dst_rd_ptr_gray)];
                dst_valid_sync[0] <= 1;
            end else begin
                dst_valid_sync[0] <= 0;
            end
        end
    end

    genvar i;
    generate
        for (i = 1; i < SYNC_STAGES; i = i + 1) begin : sync_stages
            always @(posedge dst_clk_i or negedge dst_rst_ni) begin
                if (!dst_rst_ni) begin
                    dst_data_sync[i] <= 0;
                    dst_valid_sync[i] <= 0;
                end else begin
                    dst_data_sync[i] <= dst_data_sync[i-1];
                    dst_valid_sync[i] <= dst_valid_sync[i-1];
                end
            end
        end
    endgenerate

    assign dst_data_o = dst_data_sync[SYNC_STAGES-1];
    assign dst_valid_o = dst_valid_sync[SYNC_STAGES-1];

endmodule
