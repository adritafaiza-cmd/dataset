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

    reg [WIDTH-1:0] mem [DEPTH-1:0];
    reg [ADDR_WIDTH:0] src_wr_ptr_gray, src_wr_ptr_bin, src_rd_ptr_gray, src_rd_ptr_bin;
    reg [ADDR_WIDTH:0] dst_wr_ptr_gray, dst_wr_ptr_bin, dst_rd_ptr_gray, dst_rd_ptr_bin;

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr_gray <= 0;
            src_wr_ptr_bin <= 0;
            src_rd_ptr_gray <= 0;
            src_rd_ptr_bin <= 0;
        end else begin
            if (src_valid_i && src_ready_o) begin
                mem[src_wr_ptr_bin[ADDR_WIDTH-1:0]] <= src_data_i;
                src_wr_ptr_bin <= src_wr_ptr_bin + 1;
                src_wr_ptr_gray <= src_wr_ptr_bin + 1 ^ (src_wr_ptr_bin + 1 >> 1);
            end
        end
    end

    // Cross-domain synchronization for write pointer
    reg [ADDR_WIDTH:0] src_wr_ptr_gray_sync [SYNC_STAGES-1:0];

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            for (integer i = 0; i < SYNC_STAGES; i = i + 1) begin
                src_wr_ptr_gray_sync[i] <= 0;
            end
        end else begin
            src_wr_ptr_gray_sync[0] <= src_wr_ptr_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                src_wr_ptr_gray_sync[i] <= src_wr_ptr_gray_sync[i-1];
            end
        end
    end

    // Convert synchronized write pointer to binary
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_ptr_gray <= 0;
            dst_wr_ptr_bin <= 0;
        end else begin
            dst_wr_ptr_gray <= src_wr_ptr_gray_sync[SYNC_STAGES-1];
            dst_wr_ptr_bin <= dst_wr_ptr_gray ^ (dst_wr_ptr_gray >> 1);
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr_gray <= 0;
            dst_rd_ptr_bin <= 0;
            dst_data_o <= 0;
            dst_valid_o <= 0;
        end else begin
            if (dst_valid_o && dst_ready_i) begin
                dst_rd_ptr_bin <= dst_rd_ptr_bin + 1;
                dst_rd_ptr_gray <= dst_rd_ptr_bin + 1 ^ (dst_rd_ptr_bin + 1 >> 1);
                dst_valid_o <= 0;
            end else if (dst_wr_ptr_bin != dst_rd_ptr_bin) begin
                dst_data_o <= mem[dst_rd_ptr_bin[ADDR_WIDTH-1:0]];
                dst_valid_o <= 1;
            end
        end
    end

    // Cross-domain synchronization for read pointer
    reg [ADDR_WIDTH:0] dst_rd_ptr_gray_sync [SYNC_STAGES-1:0];

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            for (integer i = 0; i < SYNC_STAGES; i = i + 1) begin
                dst_rd_ptr_gray_sync[i] <= 0;
            end
        end else begin
            dst_rd_ptr_gray_sync[0] <= dst_rd_ptr_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                dst_rd_ptr_gray_sync[i] <= dst_rd_ptr_gray_sync[i-1];
            end
        end
    end

    // Convert synchronized read pointer to binary
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_rd_ptr_gray <= 0;
            src_rd_ptr_bin <= 0;
        end else begin
            src_rd_ptr_gray <= dst_rd_ptr_gray_sync[SYNC_STAGES-1];
            src_rd_ptr_bin <= src_rd_ptr_gray ^ (src_rd_ptr_gray >> 1);
        end
    end

    // Source ready signal
    assign src_ready_o = (src_wr_ptr_bin != src_rd_ptr_bin + DEPTH);

endmodule
