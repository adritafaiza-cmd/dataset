module cdc_fifo_gray_clearable #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input                  src_clear_i,
    output                 src_clear_pending_o,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    input                  dst_clear_i,
    output                 dst_clear_pending_o,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam ADDR_WIDTH = LOG_DEPTH;

    // Source side signals
    reg [ADDR_WIDTH:0] src_wr_ptr;
    reg [ADDR_WIDTH:0] src_wr_ptr_gray;
    reg [ADDR_WIDTH:0] src_rd_ptr_gray_sync;
    reg [WIDTH-1:0]    mem [0:DEPTH-1];

    // Destination side signals
    reg [ADDR_WIDTH:0] dst_rd_ptr;
    reg [ADDR_WIDTH:0] dst_rd_ptr_gray;
    reg [ADDR_WIDTH:0] dst_wr_ptr_gray_sync;
    reg [WIDTH-1:0]    dst_data_reg;

    // Clear pending signals
    reg src_clear_pending;
    reg dst_clear_pending;

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
            src_clear_pending <= 0;
        end else begin
            if (src_clear_i) begin
                src_wr_ptr <= 0;
                src_wr_ptr_gray <= 0;
                src_clear_pending <= 1;
            end else if (src_valid_i && src_ready_o) begin
                src_wr_ptr <= src_wr_ptr + 1;
                src_wr_ptr_gray <= bin_to_gray(src_wr_ptr + 1);
            end
            if (src_clear_pending && !dst_clear_pending) begin
                src_clear_pending <= 0;
            end
        end
    end

    // Destination side logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= 0;
            dst_rd_ptr_gray <= 0;
            dst_clear_pending <= 0;
        end else begin
            if (dst_clear_i) begin
                dst_rd_ptr <= 0;
                dst_rd_ptr_gray <= 0;
                dst_clear_pending <= 1;
            end else if (dst_valid_o && dst_ready_i) begin
                dst_rd_ptr <= dst_rd_ptr + 1;
                dst_rd_ptr_gray <= bin_to_gray(dst_rd_ptr + 1);
            end
            if (dst_clear_pending && !src_clear_pending) begin
                dst_clear_pending <= 0;
            end
        end
    end

    // Cross-domain synchronization for src_wr_ptr_gray
    reg [ADDR_WIDTH:0] src_wr_ptr_gray_sync [0:SYNC_STAGES-1];
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

    // Cross-domain synchronization for dst_rd_ptr_gray
    reg [ADDR_WIDTH:0] dst_rd_ptr_gray_sync [0:SYNC_STAGES-1];
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

    // Source side ready and valid logic
    assign src_ready_o = (src_wr_ptr_gray != dst_rd_ptr_gray_sync[SYNC_STAGES-1]);
    assign src_clear_pending_o = src_clear_pending;

    // Destination side valid and data logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_reg <= 0;
            dst_valid_o <= 0;
        end else begin
            if (dst_clear_i) begin
                dst_data_reg <= 0;
                dst_valid_o <= 0;
            end else if (src_wr_ptr_gray_sync[SYNC_STAGES-1] != dst_rd_ptr_gray && !dst_valid_o) begin
                dst_data_reg <= mem[gray_to_bin(dst_rd_ptr_gray_sync[SYNC_STAGES-1]) % DEPTH];
                dst_valid_o <= 1;
            end else if (dst_valid_o && dst_ready_i) begin
                dst_valid_o <= 0;
            end
        end
    end

    // Memory write logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            mem <= '{default:0};
        end else if (src_valid_i && src_ready_o) begin
            mem[src_wr_ptr % DEPTH] <= src_data_i;
        end
    end

    // Destination side clear pending output
    assign dst_clear_pending_o = dst_clear_pending;

endmodule
