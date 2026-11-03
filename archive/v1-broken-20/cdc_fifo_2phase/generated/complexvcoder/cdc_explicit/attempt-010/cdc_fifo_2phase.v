module cdc_fifo_2phase #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
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
    logic [WIDTH-1:0]       fifo_data [0:(1<<LOG_DEPTH)-1];
    logic                   fifo_valid [0:(1<<LOG_DEPTH)-1];
    logic                   fifo_ready [0:(1<<LOG_DEPTH)-1];
    logic [LOG_DEPTH-1:0]   fifo_wr_ptr;
    logic [LOG_DEPTH-1:0]   fifo_rd_ptr;
    logic                   fifo_full;
    logic                   fifo_empty;

    // Source domain logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            fifo_wr_ptr <= 0;
            fifo_valid <= 0;
            fifo_ready <= 0;
        end else begin
            if (src_valid_i && src_ready_o) begin
                fifo_data[fifo_wr_ptr] <= src_data_i;
                fifo_valid[fifo_wr_ptr] <= 1;
                fifo_ready[fifo_wr_ptr] <= 0;
                fifo_wr_ptr <= fifo_wr_ptr + 1;
            end
        end
    end

    // Destination domain logic
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            fifo_rd_ptr <= 0;
            fifo_valid <= 0;
            fifo_ready <= 0;
        end else begin
            if (dst_ready_i && fifo_valid[fifo_rd_ptr]) begin
                fifo_ready[fifo_rd_ptr] <= 1;
                fifo_valid[fifo_rd_ptr] <= 0;
                fifo_rd_ptr <= fifo_rd_ptr + 1;
            end
        end
    end

    // Comb logic to handle ready signals
    assign src_ready_o = !fifo_full;
    assign dst_valid_o = !fifo_empty;
    assign dst_data_o = fifo_data[fifo_rd_ptr];

    // Full/empty logic
    assign fifo_full = (fifo_wr_ptr == fifo_rd_ptr) && fifo_valid[fifo_wr_ptr];
    assign fifo_empty = (fifo_wr_ptr == fifo_rd_ptr) && !fifo_valid[fifo_wr_ptr];

endmodule
