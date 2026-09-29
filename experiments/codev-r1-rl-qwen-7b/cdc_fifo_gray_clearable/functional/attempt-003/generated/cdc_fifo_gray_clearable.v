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

    localparam PTR_WIDTH = LOG_DEPTH + 1;

    // Source domain signals
    reg [PTR_WIDTH-1:0] wr_ptr_bin, wr_ptr_gray;
    reg [PTR_WIDTH-1:0] rd_ptr_gray_sync [SYNC_STAGES-1:0];
    reg [PTR_WIDTH-1:0] rd_ptr_bin;

    // Destination domain signals
    reg [PTR_WIDTH-1:0] rd_ptr_bin_dst, rd_ptr_gray_dst;
    reg [PTR_WIDTH-1:0] wr_ptr_gray_sync [SYNC_STAGES-1:0];
    reg [PTR_WIDTH-1:0] wr_ptr_bin_dst;

    // Memory
    reg [WIDTH-1:0] mem [(1 << LOG_DEPTH)-1:0];

    // Source domain clear handling
    reg src_clear_flag;
    reg [SYNC_STAGES-1:0] dst_clear_sync;

    // Destination domain clear handling
    reg dst_clear_flag;
    reg [SYNC_STAGES-1:0] src_clear_sync;

    // Synchronize dst_clear to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_clear_sync <= 0;
        end else begin
            dst_clear_sync <= {dst_clear_sync[SYNC_STAGES-2:0], dst_clear_i};
        end
    end
    wire dst_clear_synced = dst_clear_sync[SYNC_STAGES-1];

    // Synchronize src_clear to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_clear_sync <= 0;
        end else begin
            src_clear_sync <= {src_clear_sync[SYNC_STAGES-2:0], src_clear_i};
        end
    end
    wire src_clear_synced = src_clear_sync[SYNC_STAGES-1];

    // Source domain write pointer logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr_bin <= 0;
            wr_ptr_gray <= 0;
            src_clear_flag <= 0;
        end else begin
            if (src_clear_i || dst_clear_synced) begin
                wr_ptr_bin <= 0;
                wr_ptr_gray <= 0;
                src_clear_flag <= 1;
            end else if (src_clear_flag && (wr_ptr_bin == rd_ptr_bin)) begin
                src_clear_flag <= 0;
            end else if (src_valid_i && src_ready_o) begin
                wr_ptr_bin <= wr_ptr_bin + 1;
                wr_ptr_gray <= wr_ptr_bin + 1;
            end
        end
    end

    // Destination domain read pointer logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr_bin_dst <= 0;
            rd_ptr_gray_dst <= 0;
            dst_clear_flag <= 0;
        end else begin
            if (dst_clear_i || src_clear_synced) begin
                rd_ptr_bin_dst <= 0;
                rd_ptr_gray_dst <= 0;
                dst_clear_flag <= 1;
            end else if (dst_clear_flag && (rd_ptr_bin_dst == wr_ptr_bin_dst)) begin
                dst_clear_flag <= 0;
            end else if (dst_ready_i && dst_valid_o) begin
                rd_ptr_bin_dst <= rd_ptr_bin_dst + 1;
                rd_ptr_gray_dst <= rd_ptr_bin_dst + 1;
            end
        end
    end

    // Synchronize read pointer to source domain
    genvar i;
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : rd_sync
            always @(posedge src_clk_i) begin
                rd_ptr_gray_sync[i] <= rd_ptr_gray_dst;
            end
        end
    endgenerate
    wire [PTR_WIDTH-1:0] rd_ptr_bin_synced = rd_ptr_gray_sync[SYNC_STAGES-1] ^ (rd_ptr_gray_sync[SYNC_STAGES-1] >> 1);

    // Synchronize write pointer to destination domain
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : wr_sync
            always @(posedge dst_clk_i) begin
                wr_ptr_gray_sync[i] <= wr_ptr_gray;
            end
        end
    endgenerate
    wire [PTR_WIDTH-1:0] wr_ptr_bin_dst_synced = wr_ptr_gray_sync[SYNC_STAGES-1] ^ (wr_ptr_gray_sync[SYNC_STAGES-1] >> 1);

    // Memory write
    always @(posedge src_clk_i) begin
        if (src_valid_i && src_ready_o) begin
            mem[wr_ptr_bin[PTR_WIDTH-2:0]] <= src_data_i;
        end
    end

    // Memory read
    assign dst_data_o = mem[rd_ptr_bin_dst[PTR_WIDTH-2:0]];

    // Valid and ready assignments
    assign src_ready_o = !src_clear_flag && (wr_ptr_bin - rd_ptr_bin_synced) < (1 << LOG_DEPTH);
    assign dst_valid_o = (rd_ptr_bin_dst != wr_ptr_bin_dst_synced);

    // Pending flags
    assign src_clear_pending_o = src_clear_flag;
    assign dst_clear_pending_o = dst_clear_flag;

endmodule
