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

    reg [ADDR_WIDTH:0] src_wr_ptr_gray;
    reg [ADDR_WIDTH:0] src_wr_ptr_bin;
    reg [ADDR_WIDTH:0] src_rd_ptr_gray_synced;
    reg [ADDR_WIDTH:0] src_rd_ptr_bin_synced;

    reg [ADDR_WIDTH:0] dst_wr_ptr_gray_synced;
    reg [ADDR_WIDTH:0] dst_wr_ptr_bin_synced;
    reg [ADDR_WIDTH:0] dst_rd_ptr_gray;
    reg [ADDR_WIDTH:0] dst_rd_ptr_bin;

    reg [WIDTH-1:0] mem [DEPTH-1:0];

    reg src_clear_pending;
    reg dst_clear_pending;

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr_gray <= 0;
            src_wr_ptr_bin <= 0;
            src_clear_pending <= 0;
        end else begin
            if (src_clear_i) begin
                src_wr_ptr_gray <= 0;
                src_wr_ptr_bin <= 0;
                src_clear_pending <= 1;
            end else if (src_ready_o && src_valid_i) begin
                src_wr_ptr_bin <= src_wr_ptr_bin + 1;
                src_wr_ptr_gray <= src_wr_ptr_bin + 1 ^ (src_wr_ptr_bin + 1 >> 1);
            end
            if (src_clear_pending && (src_wr_ptr_bin == src_rd_ptr_bin_synced)) begin
                src_clear_pending <= 0;
            end
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr_gray <= 0;
            dst_rd_ptr_bin <= 0;
            dst_clear_pending <= 0;
        end else begin
            if (dst_clear_i) begin
                dst_rd_ptr_gray <= 0;
                dst_rd_ptr_bin <= 0;
                dst_clear_pending <= 1;
            end else if (dst_valid_o && dst_ready_i) begin
                dst_rd_ptr_bin <= dst_rd_ptr_bin + 1;
                dst_rd_ptr_gray <= dst_rd_ptr_bin + 1 ^ (dst_rd_ptr_bin + 1 >> 1);
            end
            if (dst_clear_pending && (dst_wr_ptr_bin_synced == dst_rd_ptr_bin)) begin
                dst_clear_pending <= 0;
            end
        end
    end

    // Gray code synchronization for src_wr_ptr_gray to dst_wr_ptr_gray_synced
    genvar i;
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_src_wr_ptr
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
                        sync_stage <= sync_src_wr_ptr[i-1].sync_stage;
                    end
                end
            end
            if (i == SYNC_STAGES - 1) begin
                assign dst_wr_ptr_gray_synced = sync_stage;
            end
        end
    endgenerate

    // Gray code synchronization for dst_rd_ptr_gray to src_rd_ptr_gray_synced
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_dst_rd_ptr
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
                        sync_stage <= sync_dst_rd_ptr[i-1].sync_stage;
                    end
                end
            end
            if (i == SYNC_STAGES - 1) begin
                assign src_rd_ptr_gray_synced = sync_stage;
            end
        end
    endgenerate

    // Binary conversion for src_rd_ptr_gray_synced
    always @(*) begin
        src_rd_ptr_bin_synced = src_rd_ptr_gray_synced[ADDR_WIDTH];
        for (i = ADDR_WIDTH - 1; i >= 0; i = i - 1) begin
            src_rd_ptr_bin_synced[i] = src_rd_ptr_gray_synced[i] ^ src_rd_ptr_bin_synced[i+1];
        end
    end

    // Binary conversion for dst_wr_ptr_gray_synced
    always @(*) begin
        dst_wr_ptr_bin_synced = dst_wr_ptr_gray_synced[ADDR_WIDTH];
        for (i = ADDR_WIDTH - 1; i >= 0; i = i - 1) begin
            dst_wr_ptr_bin_synced[i] = dst_wr_ptr_gray_synced[i] ^ dst_wr_ptr_bin_synced[i+1];
        end
    end

    // Source ready logic
    assign src_ready_o = (src_wr_ptr_bin + 1 != src_rd_ptr_bin_synced) && !src_clear_pending;

    // Destination valid logic
    assign dst_valid_o = (dst_wr_ptr_bin_synced != dst_rd_ptr_bin) && !dst_clear_pending;

    // Data memory write
    always @(posedge src_clk_i) begin
        if (src_ready_o && src_valid_i) begin
            mem[src_wr_ptr_bin[ADDR_WIDTH-1:0]] <= src_data_i;
        end
    end

    // Data memory read
    always @(posedge dst_clk_i) begin
        if (dst_valid_o && dst_ready_i) begin
            dst_data_o <= mem[dst_rd_ptr_bin[ADDR_WIDTH-1:0]];
        end
    end

    // Clear pending outputs
    assign src_clear_pending_o = src_clear_pending;
    assign dst_clear_pending_o = dst_clear_pending;

endmodule
