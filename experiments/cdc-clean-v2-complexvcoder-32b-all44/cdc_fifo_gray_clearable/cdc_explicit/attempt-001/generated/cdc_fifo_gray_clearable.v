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

    // Internal signals
    reg [LOG_DEPTH:0]      src_gray_ptr;
    reg [LOG_DEPTH:0]      dst_gray_ptr;
    reg [LOG_DEPTH:0]      src_gray_ptr_synced;
    reg [LOG_DEPTH:0]      dst_gray_ptr_synced;
    reg                    src_clear_synced;
    reg                    dst_clear_synced;
    reg [WIDTH-1:0]        fifo_mem [0:(1<<LOG_DEPTH)-1];
    reg [LOG_DEPTH-1:0]    src_write_ptr;
    reg [LOG_DEPTH-1:0]    src_read_ptr;
    reg [LOG_DEPTH-1:0]    dst_write_ptr;
    reg [LOG_DEPTH-1:0]    dst_read_ptr;
    wire                   src_full;
    wire                   src_empty;
    wire                   dst_full;
    wire                   dst_empty;
    reg                    src_clear_pending;
    reg                    dst_clear_pending;

    // Gray code counters
    gray_counter #(LOG_DEPTH+1) gray_counter_src (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .clear_i(src_clear_i),
        .gray_o(src_gray_ptr)
    );

    gray_counter #(LOG_DEPTH+1) gray_counter_dst (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .clear_i(dst_clear_i),
        .gray_o(dst_gray_ptr)
    );

    // Synchronizers
    sync_register #(LOG_DEPTH+1) sync_src_to_dst (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .d_i(src_gray_ptr),
        .q_o(src_gray_ptr_synced)
    );

    sync_register #(LOG_DEPTH+1) sync_dst_to_src (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .d_i(dst_gray_ptr),
        .q_o(dst_gray_ptr_synced)
    );

    sync_register #(1) sync_src_clear (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .d_i(src_clear_i),
        .q_o(src_clear_synced)
    );

    sync_register #(1) sync_dst_clear (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .d_i(dst_clear_i),
        .q_o(dst_clear_synced)
    );

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_write_ptr <= 0;
            src_read_ptr <= 0;
            src_clear_pending <= 0;
        end else if (src_clear_i) begin
            src_write_ptr <= 0;
            src_read_ptr <= 0;
            src_clear_pending <= 1;
        end else if (src_valid_i && src_ready_o) begin
            fifo_mem[src_write_ptr] <= src_data_i;
            src_write_ptr <= src_write_ptr + 1;
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_write_ptr <= 0;
            dst_read_ptr <= 0;
            dst_clear_pending <= 0;
        end else if (dst_clear_i) begin
            dst_write_ptr <= 0;
            dst_read_ptr <= 0;
            dst_clear_pending <= 1;
        end else if (dst_valid_o && dst_ready_i) begin
            dst_read_ptr <= dst_read_ptr + 1;
        end
    end

    // Source ready and full
    assign src_full = (src_gray_ptr[LOG_DEPTH:1] == src_gray_ptr_synced[LOG_DEPTH:1]) && (src_gray_ptr[0] != src_gray_ptr_synced[0]);
    assign src_ready_o = !src_full;

    // Destination valid and empty
    assign dst_empty = (dst_gray_ptr[LOG_DEPTH:1] == dst_gray_ptr_synced[LOG_DEPTH:1]) && (dst_gray_ptr[0] == dst_gray_ptr_synced[0]);
    assign dst_valid_o = !dst_empty;

    assign dst_data_o = fifo_mem[dst_read_ptr];

    // Clear pending outputs
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_pending <= 0;
        end else if (src_clear_i) begin
            src_clear_pending <= 1;
        end else if (src_clear_pending && (src_gray_ptr == src_gray_ptr_synced)) begin
            src_clear_pending <= 0;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_pending <= 0;
        end else if (dst_clear_i) begin
            dst_clear_pending <= 1;
        end else if (dst_clear_pending && (dst_gray_ptr == dst_gray_ptr_synced)) begin
            dst_clear_pending <= 0;
        end
    end

    assign src_clear_pending_o = src_clear_pending;
    assign dst_clear_pending_o = dst_clear_pending;

endmodule

module gray_counter #(
    parameter WIDTH = 4
)(
    input                  clk_i,
    input                  rst_ni,
    input                  clear_i,
    output [WIDTH-1:0]     gray_o
);

    reg [WIDTH-1:0]        binary_ptr;
    reg [WIDTH-1:0]        gray_ptr;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            binary_ptr <= 0;
            gray_ptr <= 0;
        end else if (clear_i) begin
            binary_ptr <= 0;
            gray_ptr <= 0;
        end else begin
            binary_ptr <= binary_ptr + 1;
            gray_ptr <= (binary_ptr >> 1) ^ binary_ptr;
        end
    end

    assign gray_o = gray_ptr;

endmodule

module sync_register #(
    parameter WIDTH = 1
)(
    input                  clk_i,
    input                  rst_ni,
    input  [WIDTH-1:0]     d_i,
    output [WIDTH-1:0]     q_o
);

    reg [WIDTH-1:0]        sync_stage_1;
    reg [WIDTH-1:0]        sync_stage_2;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_stage_1 <= 0;
            sync_stage_2 <= 0;
        end else begin
            sync_stage_1 <= d_i;
            sync_stage_2 <= sync_stage_1;
        end
    end

    assign q_o = sync_stage_2;

endmodule
