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
    reg [ADDR_WIDTH:0] src_wr_ptr_gray;
    reg [ADDR_WIDTH:0] src_wr_ptr_bin;
    reg [ADDR_WIDTH:0] src_rd_ptr_gray_sync;
    reg [WIDTH-1:0]    mem [0:DEPTH-1];
    reg                src_clear_pending;
    reg                src_clear;

    // Destination side signals
    reg [ADDR_WIDTH:0] dst_rd_ptr_gray;
    reg [ADDR_WIDTH:0] dst_rd_ptr_bin;
    reg [ADDR_WIDTH:0] dst_wr_ptr_gray_sync;
    reg                dst_clear_pending;
    reg                dst_clear;

    // Clear request synchronization
    reg [SYNC_STAGES-1:0] src_clear_sync;
    reg [SYNC_STAGES-1:0] dst_clear_sync;

    // Source side logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr_gray <= 0;
            src_wr_ptr_bin <= 0;
            src_clear_pending <= 0;
            src_clear <= 0;
        end else begin
            if (src_clear_i) begin
                src_clear_pending <= 1;
                src_clear <= 1;
            end else if (src_clear_pending && src_clear_sync[SYNC_STAGES-1]) begin
                src_wr_ptr_gray <= 0;
                src_wr_ptr_bin <= 0;
                src_clear_pending <= 0;
                src_clear <= 0;
            end else if (src_valid_i && src_ready_o) begin
                mem[src_wr_ptr_bin[ADDR_WIDTH-1:0]] <= src_data_i;
                src_wr_ptr_bin <= src_wr_ptr_bin + 1;
                src_wr_ptr_gray <= (src_wr_ptr_bin + 1) ^ ((src_wr_ptr_bin + 1) >> 1);
            end
        end
    end

    // Destination side logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr_gray <= 0;
            dst_rd_ptr_bin <= 0;
            dst_clear_pending <= 0;
            dst_clear <= 0;
        end else begin
            if (dst_clear_i) begin
                dst_clear_pending <= 1;
                dst_clear <= 1;
            end else if (dst_clear_pending && dst_clear_sync[SYNC_STAGES-1]) begin
                dst_rd_ptr_gray <= 0;
                dst_rd_ptr_bin <= 0;
                dst_clear_pending <= 0;
                dst_clear <= 0;
            end else if (dst_valid_o && dst_ready_i) begin
                dst_rd_ptr_bin <= dst_rd_ptr_bin + 1;
                dst_rd_ptr_gray <= (dst_rd_ptr_bin + 1) ^ ((dst_rd_ptr_bin + 1) >> 1);
            end
        end
    end

    // Gray code synchronization for src_wr_ptr_gray to dst_wr_ptr_gray_sync
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_ptr_gray_sync <= 0;
        end else begin
            dst_wr_ptr_gray_sync <= src_wr_ptr_gray;
        end
    end

    // Gray code synchronization for dst_rd_ptr_gray to src_rd_ptr_gray_sync
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_rd_ptr_gray_sync <= 0;
        end else begin
            src_rd_ptr_gray_sync <= dst_rd_ptr_gray;
        end
    end

    // Convert synchronized Gray code to binary
    always @(*) begin
        dst_wr_ptr_bin = dst_wr_ptr_gray_sync ^ (dst_wr_ptr_gray_sync >> 1);
        src_rd_ptr_bin = src_rd_ptr_gray_sync ^ (src_rd_ptr_gray_sync >> 1);
    end

    // Source side ready and valid logic
    assign src_ready_o = (src_wr_ptr_bin != (src_rd_ptr_bin + 1));
    assign src_clear_pending_o = src_clear_pending;

    // Destination side valid and data logic
    assign dst_valid_o = (dst_wr_ptr_bin != dst_rd_ptr_bin);
    assign dst_data_o = mem[dst_rd_ptr_bin[ADDR_WIDTH-1:0]];
    assign dst_clear_pending_o = dst_clear_pending;

    // Clear request synchronization
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_sync <= 0;
        end else begin
            src_clear_sync <= {src_clear_sync[SYNC_STAGES-2:0], src_clear_i};
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_sync <= 0;
        end else begin
            dst_clear_sync <= {dst_clear_sync[SYNC_STAGES-2:0], dst_clear_i};
        end
    end

endmodule
