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
    logic [WIDTH-1:0]       fifo_data [0:2**LOG_DEPTH-1];
    logic [LOG_DEPTH:0]     fifo_wr_ptr;
    logic [LOG_DEPTH:0]     fifo_rd_ptr;
    logic                   fifo_full;
    logic                   fifo_empty;

    // Asynchronous reset flip-flops
    async_ff #(.WIDTH(1)) src_rst_ff (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .d_i(1'b0),
        .q_o(src_rst_ff_q_o)
    );

    async_ff #(.WIDTH(1)) dst_rst_ff (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .d_i(1'b0),
        .q_o(dst_rst_ff_q_o)
    );

    // FIFO depth 8
    fifo_depth_8 #(.WIDTH(WIDTH), .LOG_DEPTH(LOG_DEPTH)) fifo (
        .src_data_i(src_data_i),
        .src_valid_i(src_valid_i),
        .src_ready_o(src_ready_o),
        .dst_data_o(dst_data_o),
        .dst_valid_o(dst_valid_o),
        .dst_ready_i(dst_ready_i),
        .src_rst_ni(src_rst_ff_q_o),
        .dst_rst_ni(dst_rst_ff_q_o)
    );

endmodule

module async_ff #(
    parameter WIDTH = 1
)(
    input                  rst_ni,
    input                  clk_i,
    input  [WIDTH-1:0]     d_i,
    output reg [WIDTH-1:0] q_o
);

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            q_o <= {WIDTH{1'b0}};
        end else begin
            q_o <= d_i;
        end
    end

endmodule

module fifo_depth_8 #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output reg             src_ready_o,
    output [WIDTH-1:0]     dst_data_o,
    output reg             dst_valid_o,
    input                  dst_ready_i,
    input                  src_rst_ni,
    input                  dst_rst_ni
);

    // Internal signals
    logic [WIDTH-1:0]       fifo_data [0:2**LOG_DEPTH-1];
    logic [LOG_DEPTH:0]     fifo_wr_ptr;
    logic [LOG_DEPTH:0]     fifo_rd_ptr;
    logic                   fifo_full;
    logic                   fifo_empty;

    // Write pointer logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            fifo_wr_ptr <= 0;
        end else if (src_valid_i && !fifo_full && dst_ready_i) begin
            fifo_data[fifo_wr_ptr] <= src_data_i;
            fifo_wr_ptr <= fifo_wr_ptr + 1;
        end
    end

    // Read pointer logic
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            fifo_rd_ptr <= 0;
        end else if (dst_valid_o && dst_ready_i) begin
            fifo_rd_ptr <= fifo_rd_ptr + 1;
        end
    end

    // FIFO full and empty logic
    assign fifo_full = (fifo_wr_ptr - fifo_rd_ptr) == 2**LOG_DEPTH;
    assign fifo_empty = fifo_wr_ptr == fifo_rd_ptr;

    // Output logic
    assign src_ready_o = !fifo_full;
    assign dst_data_o = fifo_data[fifo_rd_ptr];
    assign dst_valid_o = !fifo_empty && dst_ready_i;

endmodule
