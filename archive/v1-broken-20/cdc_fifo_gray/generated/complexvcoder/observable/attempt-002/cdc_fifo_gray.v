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
    localparam ADDR_WIDTH = $clog2(DEPTH);

    // Internal signals
    logic [WIDTH-1:0] src_fifo [0:DEPTH-1];
    logic [ADDR_WIDTH-1:0] src_wr_ptr, src_rd_ptr;
    logic [ADDR_WIDTH:0] src_count;
    logic [WIDTH-1:0] dst_fifo [0:DEPTH-1];
    logic [ADDR_WIDTH-1:0] dst_wr_ptr, dst_rd_ptr;
    logic [ADDR_WIDTH:0] dst_count;
    logic src_ready_int, dst_valid_int;

    // Source FIFO logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= 0;
            src_rd_ptr <= 0;
            src_count <= 0;
        end else begin
            if (src_valid_i && src_ready_int && src_count < DEPTH) begin
                src_fifo[src_wr_ptr] <= src_data_i;
                src_wr_ptr <= src_wr_ptr + 1;
                src_count <= src_count + 1;
            end
        end
    end

    assign src_ready_int = src_count < DEPTH;
    assign src_ready_o = src_ready_int;

    // Destination FIFO logic
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= 0;
            dst_count <= 0;
        end else begin
            if (dst_ready_i && dst_valid_int && dst_count > 0) begin
                dst_rd_ptr <= dst_rd_ptr + 1;
                dst_count <= dst_count - 1;
            end
        end
    end

    assign dst_valid_int = dst_count > 0;
    assign dst_valid_o = dst_valid_int;
    assign dst_data_o = dst_fifo[dst_rd_ptr];

endmodule
