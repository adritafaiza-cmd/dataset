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

    // Internal signals
    logic [WIDTH-1:0] intermediate_data;
    logic [LOG_DEPTH-1:0] src_gray_ptr, dst_gray_ptr;
    logic [LOG_DEPTH-1:0] src_gray_ptr_gray, dst_gray_ptr_gray;
    logic [LOG_DEPTH-1:0] src_gray_ptr_gray_sync[SYNC_STAGES];
    logic [LOG_DEPTH-1:0] dst_gray_ptr_gray_sync[SYNC_STAGES];
    logic src_fifo_full, src_fifo_empty, dst_fifo_full, dst_fifo_empty;
    logic src_fifo_read, src_fifo_write, dst_fifo_read, dst_fifo_write;

    // FIFO instances
    fifo_gray #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) src_fifo (
        .src_rst_ni(src_rst_ni),
        .src_clk_i(src_clk_i),
        .src_data_i(src_data_i),
        .src_valid_i(src_valid_i),
        .src_ready_o(src_ready_o),
        .data_out(intermediate_data),
        .valid_out(src_fifo_valid),
        .ready_in(src_fifo_write)
    );

    fifo_gray #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) dst_fifo (
        .src_rst_ni(dst_rst_ni),
        .src_clk_i(dst_clk_i),
        .src_data_i(intermediate_data),
        .src_valid_i(src_fifo_valid),
        .src_ready_o(dst_ready_i),
        .data_out(dst_data_o),
        .valid_out(dst_valid_o),
        .ready_in(dst_fifo_write)
    );

    // Gray encoding logic
    assign src_gray_ptr_gray = src_gray_ptr ^ (src_gray_ptr >> 1);
    assign dst_gray_ptr_gray = dst_gray_ptr ^ (dst_gray_ptr >> 1);

    // Sync logic for Gray pointers
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_gray_ptr_gray_sync <= '{default: 0};
        end else begin
            src_gray_ptr_gray_sync <= {src_gray_ptr_gray_sync[SYNC_STAGES-2:0], src_gray_ptr_gray};
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_gray_ptr_gray_sync <= '{default: 0};
        end else begin
            dst_gray_ptr_gray_sync <= {dst_gray_ptr_gray_sync[SYNC_STAGES-2:0], dst_gray_ptr_gray};
        end
    end

    // Pointer synchronization logic
    assign src_gray_ptr = src_gray_ptr_gray_sync[SYNC_STAGES-1];
    assign dst_gray_ptr = dst_gray_ptr_gray_sync[SYNC_STAGES-1];

    // FIFO full and empty flags
    assign src_fifo_full = (src_gray_ptr_gray == dst_gray_ptr_gray) && src_fifo_valid;
    assign src_fifo_empty = (src_gray_ptr_gray == dst_gray_ptr_gray) && !src_fifo_valid;
    assign dst_fifo_full = (src_gray_ptr_gray == dst_gray_ptr_gray) && dst_fifo_valid;
    assign dst_fifo_empty = (src_gray_ptr_gray == dst_gray_ptr_gray) && !dst_fifo_valid;

    // Control logic
    assign src_fifo_write = src_valid_i && src_ready_o && !src_fifo_full;
    assign dst_fifo_read = dst_ready_i && dst_fifo_valid;

    // Pointer update logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_gray_ptr <= 0;
        end else if (src_fifo_write) begin
            src_gray_ptr <= src_gray_ptr + 1;
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_gray_ptr <= 0;
        end else if (dst_fifo_read) begin
            dst_gray_ptr <= dst_gray_ptr + 1;
        end
    end

endmodule
