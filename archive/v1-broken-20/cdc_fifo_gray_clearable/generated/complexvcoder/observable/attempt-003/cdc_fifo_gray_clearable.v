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

    // Internal signals for source side
    reg [WIDTH-1:0] src_data_reg [0:2**LOG_DEPTH-1];
    reg [LOG_DEPTH:0] src_wr_ptr_reg, src_rd_ptr_reg;
    reg src_full_reg, src_empty_reg;
    reg src_clear_pending_reg;

    // Internal signals for destination side
    reg [WIDTH-1:0] dst_data_reg [0:2**LOG_DEPTH-1];
    reg [LOG_DEPTH:0] dst_wr_ptr_reg, dst_rd_ptr_reg;
    reg dst_full_reg, dst_empty_reg;
    reg dst_clear_pending_reg;

    // Synchronization logic for source side
    wire [WIDTH-1:0] sync_src_data;
    wire sync_src_valid;
    wire sync_src_ready;

    sync_fifo_gray_clearable #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) sync_fifo_gray_clearable_src (
        .src_rst_ni(src_rst_ni),
        .src_clk_i(src_clk_i),
        .src_clear_i(src_clear_i),
        .src_clear_pending_o(src_clear_pending_reg),
        .src_data_i(src_data_i),
        .src_valid_i(src_valid_i),
        .src_ready_o(src_ready_o),
        .dst_rst_ni(dst_rst_ni),
        .dst_clk_i(dst_clk_i),
        .dst_clear_i(dst_clear_i),
        .dst_clear_pending_o(src_clear_pending_o),
        .dst_data_o(sync_src_data),
        .dst_valid_o(sync_src_valid),
        .dst_ready_i(sync_src_ready)
    );

    // Synchronization logic for destination side
    wire [WIDTH-1:0] sync_dst_data;
    wire sync_dst_valid;
    wire sync_dst_ready;

    sync_fifo_gray_clearable #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) sync_fifo_gray_clearable_dst (
        .src_rst_ni(dst_rst_ni),
        .src_clk_i(dst_clk_i),
        .src_clear_i(dst_clear_i),
        .src_clear_pending_o(dst_clear_pending_reg),
        .src_data_i(sync_dst_data),
        .src_valid_i(sync_dst_valid),
        .src_ready_o(sync_dst_ready),
        .dst_rst_ni(src_rst_ni),
        .dst_clk_i(src_clk_i),
        .dst_clear_i(src_clear_i),
        .dst_clear_pending_o(dst_clear_pending_o),
        .dst_data_o(dst_data_o),
        .dst_valid_o(dst_valid_o),
        .dst_ready_i(src_ready_o)
    );

    // Source side logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_data_reg <= {WIDTH{1'b0}};
            src_wr_ptr_reg <= 0;
            src_rd_ptr_reg <= 0;
            src_full_reg <= 0;
            src_empty_reg <= 1;
            src_clear_pending_reg <= 0;
        end else if (src_clear_i) begin
            src_data_reg <= {WIDTH{1'b0}};
            src_wr_ptr_reg <= 0;
            src_rd_ptr_reg <= 0;
            src_full_reg <= 0;
            src_empty_reg <= 1;
            src_clear_pending_reg <= 0;
        end else if (src_valid_i && sync_src_ready) begin
            src_data_reg[src_wr_ptr_reg] <= src_data_i;
            src_wr_ptr_reg <= (src_wr_ptr_reg + 1) % (2**LOG_DEPTH);
            if (src_full_reg) begin
                src_clear_pending_reg <= 1;
            end else begin
                src_clear_pending_reg <= 0;
                src_full_reg <= (src_wr_ptr_reg + 1) % (2**LOG_DEPTH) == src_rd_ptr_reg;
                src_empty_reg <= 0;
            end
        end
    end

    // Destination side logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_reg <= {WIDTH{1'b0}};
            dst_wr_ptr_reg <= 0;
            dst_rd_ptr_reg <= 0;
            dst_full_reg <= 0;
            dst_empty_reg <= 1;
            dst_clear_pending_reg <= 0;
        end else if (dst_clear_i) begin
            dst_data_reg <= {WIDTH{1'b0}};
            dst_wr_ptr_reg <= 0;
            dst_rd_ptr_reg <= 0;
            dst_full_reg <= 0;
            dst_empty_reg <= 1;
            dst_clear_pending_reg <= 0;
        end else if (sync_dst_valid && dst_ready_i) begin
            dst_data_reg[dst_rd_ptr_reg] <= sync_dst_data;
            dst_rd_ptr_reg <= (dst_rd_ptr_reg + 1) % (2**LOG_DEPTH);
            if (dst_full_reg) begin
                dst_clear_pending_reg <= 1;
            end else begin
                dst_clear_pending_reg <= 0;
                dst_full_reg <= (dst_wr_ptr_reg + 1) % (2**LOG_DEPTH) == dst_rd_ptr_reg;
                dst_empty_reg <= 0;
            end
        end
    end

    assign src_ready_o = !src_full_reg;
    assign dst_valid_o = !dst_empty_reg;

endmodule
