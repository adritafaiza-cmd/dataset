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
    reg [SYNC_STAGES-1:0] dst_clear_sync;
    wire dst_clear_synced;
    reg src_clear_pending;

    // Destination domain signals
    reg [SYNC_STAGES-1:0] src_clear_sync;
    wire src_clear_synced;
    reg dst_clear_pending;

    // FIFO memory
    reg [WIDTH-1:0] mem [0:(1 << LOG_DEPTH)-1];

    // Pointers
    reg [PTR_WIDTH-1:0] wr_ptr_bin, wr_ptr_gray, wr_ptr_bin_next;
    reg [PTR_WIDTH-1:0] rd_ptr_bin, rd_ptr_gray, rd_ptr_bin_next;

    // Synchronized pointers
    reg [PTR_WIDTH-1:0] wr_ptr_gray_sync [SYNC_STAGES-1:0];
    reg [PTR_WIDTH-1:0] rd_ptr_gray_sync [SYNC_STAGES-1:0];

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_clear_sync <= 0;
            src_clear_pending <= 0;
        end else begin
            dst_clear_sync <= {dst_clear_sync[SYNC_STAGES-2:0], dst_clear_i};
            if (src_clear_i || dst_clear_synced)
                src_clear_pending <= 1;
            else if (dst_clear_synced)
                src_clear_pending <= 0;
        end
    end

    assign dst_clear_synced = dst_clear_sync[SYNC_STAGES-1];
    assign src_clear_pending_o = src_clear_pending;

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_clear_sync <= 0;
            dst_clear_pending <= 0;
        end else begin
            src_clear_sync <= {src_clear_sync[SYNC_STAGES-2:0], src_clear_i};
            if (dst_clear_i || src_clear_synced)
                dst_clear_pending <= 1;
            else if (src_clear_synced)
                dst_clear_pending <= 0;
        end
    end

    assign src_clear_synced = src_clear_sync[SYNC_STAGES-1];
    assign dst_clear_pending_o = dst_clear_pending;

    // Write pointer logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr_bin <= 0;
        end else if (src_clear_pending) begin
            wr_ptr_bin <= 0;
        end else if (src_valid_i && src_ready_o) begin
            wr_ptr_bin <= wr_ptr_bin + 1;
        end
    end

    // Read pointer logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr_bin <= 0;
        end else if (dst_clear_pending) begin
            rd_ptr_bin <= 0;
        end else if (dst_ready_i && dst_valid_o) begin
            rd_ptr_bin <= rd_ptr_bin + 1;
        end
    end

    // Gray code conversion
    assign wr_ptr_gray = (wr_ptr_bin >> 1) ^ wr_ptr_bin;
    assign rd_ptr_gray = (rd_ptr_bin >> 1) ^ rd_ptr_bin;

    // Synchronize read pointer to write domain
    integer i;
    always @(posedge src_clk_i) begin
        if (src_clear_pending) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1)
                wr_ptr_gray_sync[i] <= 0;
        end else begin
            wr_ptr_gray_sync[0] <= rd_ptr_gray;
            for (i = 1; i < SYNC_STAGES; i = i + 1)
                wr_ptr_gray_sync[i] <= wr_ptr_gray_sync[i-1];
        end
    end

    // Synchronize write pointer to read domain
    always @(posedge dst_clk_i) begin
        if (dst_clear_pending) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1)
                rd_ptr_gray_sync[i] <= 0;
        end else begin
            rd_ptr_gray_sync[0] <= wr_ptr_gray;
            for (i = 1; i < SYNC_STAGES; i = i + 1)
                rd_ptr_gray_sync[i] <= rd_ptr_gray_sync[i-1];
        end
    end

    // Full and empty conditions
    wire full = (wr_ptr_gray == rd_ptr_gray_sync[SYNC_STAGES-1]);
    wire empty = (rd_ptr_gray == wr_ptr_gray_sync[SYNC_STAGES-1]);

    // Source ready
    assign src_ready_o = !full;

    // Destination valid
    assign dst_valid_o = !empty;

    // Memory write
    always @(posedge src_clk_i) begin
        if (src_valid_i && src_ready_o && !src_clear_pending)
            mem[wr_ptr_bin[LOG_DEPTH-1:0]] <= src_data_i;
    end

    // Memory read
    assign dst_data_o = mem[rd_ptr_bin[LOG_DEPTH-1:0]];

endmodule
