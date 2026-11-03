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

    // Source domain signals
    reg [ADDR_WIDTH:0] src_wr_ptr_gray;
    reg [ADDR_WIDTH:0] src_wr_ptr_bin;
    reg [ADDR_WIDTH:0] src_rd_ptr_gray_sync;
    reg [WIDTH-1:0]    mem [0:DEPTH-1];
    reg                src_clear_pending;
    reg                src_clear;

    // Destination domain signals
    reg [ADDR_WIDTH:0] dst_rd_ptr_gray;
    reg [ADDR_WIDTH:0] dst_rd_ptr_bin;
    reg [ADDR_WIDTH:0] dst_wr_ptr_gray_sync;
    reg [WIDTH-1:0]    dst_data_reg;
    reg                dst_valid_reg;
    reg                dst_clear_pending;
    reg                dst_clear;

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
        for (i = ADDR_WIDTH-1; i > 0; i = i - 1) begin
            bin[i-1] = bin[i] ^ bin[i-1];
        end
        gray_to_bin = bin;
    endfunction

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr_gray <= 0;
            src_wr_ptr_bin <= 0;
            src_clear_pending <= 0;
            src_clear <= 0;
        end else begin
            if (src_clear_i) begin
                src_wr_ptr_gray <= 0;
                src_wr_ptr_bin <= 0;
                src_clear_pending <= 1;
                src_clear <= 1;
            end else if (src_clear_pending && (src_wr_ptr_bin == dst_rd_ptr_gray_sync)) begin
                src_clear_pending <= 0;
                src_clear <= 0;
            end else if (src_valid_i && src_ready_o) begin
                mem[src_wr_ptr_bin[ADDR_WIDTH-1:0]] <= src_data_i;
                src_wr_ptr_bin <= src_wr_ptr_bin + 1;
                src_wr_ptr_gray <= bin_to_gray(src_wr_ptr_bin + 1);
            end
        end
    end

    // Synchronize write pointer to destination domain
    genvar i;
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_wr_ptr
            reg [ADDR_WIDTH:0] sync_stage;
            if (i == 0) begin
                always @(posedge dst_clk_i or negedge dst_rst_ni) begin
                    if (!dst_rst_ni) begin
                        sync_stage <= 0;
                    end else begin
                        sync_stage <= src_wr_ptr_gray;
                    end
                end
            end else begin
                always @(posedge dst_clk_i or negedge dst_rst_ni) begin
                    if (!dst_rst_ni) begin
                        sync_stage <= 0;
                    end else begin
                        sync_stage <= sync_wr_ptr[i-1].sync_stage;
                    end
                end
            end
            if (i == SYNC_STAGES - 1) begin
                always @(posedge dst_clk_i or negedge dst_rst_ni) begin
                    if (!dst_rst_ni) begin
                        dst_wr_ptr_gray_sync <= 0;
                    end else begin
                        dst_wr_ptr_gray_sync <= sync_stage;
                    end
                end
            end
        end
    endgenerate

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr_gray <= 0;
            dst_rd_ptr_bin <= 0;
            dst_clear_pending <= 0;
            dst_clear <= 0;
            dst_data_reg <= 0;
            dst_valid_reg <= 0;
        end else begin
            if (dst_clear_i) begin
                dst_rd_ptr_gray <= 0;
                dst_rd_ptr_bin <= 0;
                dst_clear_pending <= 1;
                dst_clear <= 1;
            end else if (dst_clear_pending && (dst_rd_ptr_bin == dst_wr_ptr_gray_sync)) begin
                dst_clear_pending <= 0;
                dst_clear <= 0;
            end else if (dst_valid_reg && dst_ready_i) begin
                dst_valid_reg <= 0;
            end else if (!dst_valid_reg && (dst_wr_ptr_gray_sync != dst_rd_ptr_gray)) begin
                dst_data_reg <= mem[dst_rd_ptr_bin[ADDR_WIDTH-1:0]];
                dst_valid_reg <= 1;
                dst_rd_ptr_bin <= dst_rd_ptr_bin + 1;
                dst_rd_ptr_gray <= bin_to_gray(dst_rd_ptr_bin + 1);
            end
        end
    end

    // Synchronize read pointer to source domain
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_rd_ptr
            reg [ADDR_WIDTH:0] sync_stage;
            if (i == 0) begin
                always @(posedge src_clk_i or negedge src_rst_ni) begin
                    if (!src_rst_ni) begin
                        sync_stage <= 0;
                    end else begin
                        sync_stage <= dst_rd_ptr_gray;
                    end
                end
            end else begin
                always @(posedge src_clk_i or negedge src_rst_ni) begin
                    if (!src_rst_ni) begin
                        sync_stage <= 0;
                    end else begin
                        sync_stage <= sync_rd_ptr[i-1].sync_stage;
                    end
                end
            end
            if (i == SYNC_STAGES - 1) begin
                always @(posedge src_clk_i or negedge src_rst_ni) begin
                    if (!src_rst_ni) begin
                        src_rd_ptr_gray_sync <= 0;
                    end else begin
                        src_rd_ptr_gray_sync <= sync_stage;
                    end
                end
            end
        end
    endgenerate

    // Source ready signal
    assign src_ready_o = (src_wr_ptr_bin != gray_to_bin(src_rd_ptr_gray_sync) + DEPTH);

    // Destination data and valid signals
    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

    // Clear pending outputs
    assign src_clear_pending_o = src_clear_pending;
    assign dst_clear_pending_o = dst_clear_pending;

endmodule
