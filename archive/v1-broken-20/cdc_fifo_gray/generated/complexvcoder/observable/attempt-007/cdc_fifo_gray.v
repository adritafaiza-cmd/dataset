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
    logic [WIDTH-1:0]       fifo_gray_data [2**LOG_DEPTH-1:0];
    logic                   fifo_gray_valid [2**LOG_DEPTH-1:0];
    logic                   fifo_gray_ready [2**LOG_DEPTH-1:0];
    logic [LOG_DEPTH-1:0]   fifo_gray_wr_ptr;
    logic [LOG_DEPTH-1:0]   fifo_gray_rd_ptr;
    logic [LOG_DEPTH:0]     fifo_gray_count;

    // FIFO Gray module instance
    fifo_gray #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_gray_inst (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .data_i(src_data_i),
        .valid_i(src_valid_i),
        .ready_o(src_ready_o),
        .data_o(fifo_gray_data[fifo_gray_wr_ptr]),
        .valid_o(fifo_gray_valid[fifo_gray_wr_ptr]),
        .ready_i(fifo_gray_ready[fifo_gray_wr_ptr])
    );

    // Synchronous FIFO module instance
    sync_fifo #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) sync_fifo_inst (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .data_i(fifo_gray_data[fifo_gray_wr_ptr]),
        .valid_i(fifo_gray_valid[fifo_gray_wr_ptr]),
        .ready_o(fifo_gray_ready[fifo_gray_wr_ptr]),
        .data_o(fifo_gray_data[fifo_gray_rd_ptr]),
        .valid_o(fifo_gray_valid[fifo_gray_rd_ptr]),
        .ready_i(fifo_gray_ready[fifo_gray_rd_ptr])
    );

    // FIFO control logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            fifo_gray_wr_ptr <= 0;
            fifo_gray_rd_ptr <= 0;
            fifo_gray_count <= 0;
        end else begin
            if (src_valid_i && src_ready_o && fifo_gray_count < 2**LOG_DEPTH) begin
                fifo_gray_wr_ptr <= fifo_gray_wr_ptr + 1;
                fifo_gray_count <= fifo_gray_count + 1;
            end
            if (fifo_gray_valid[fifo_gray_rd_ptr] && dst_ready_i) begin
                fifo_gray_rd_ptr <= fifo_gray_rd_ptr + 1;
                fifo_gray_count <= fifo_gray_count - 1;
            end
        end
    end

    // Output logic
    assign dst_data_o = fifo_gray_data[fifo_gray_rd_ptr];
    assign dst_valid_o = fifo_gray_valid[fifo_gray_rd_ptr];
    assign src_ready_o = (fifo_gray_count < 2**LOG_DEPTH);

endmodule
