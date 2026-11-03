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
    logic [WIDTH-1:0] fifo [0:2**LOG_DEPTH-1];
    logic [LOG_DEPTH:0] wr_ptr, rd_ptr;
    logic full, empty;

    // Synchronizers for input and output
    logic [WIDTH-1:0] src_data_sync;
    logic src_valid_sync;
    logic src_ready_sync;
    logic dst_valid_sync;
    logic dst_ready_sync;

    // Synchronizer for source data
    fifo_sync #(.WIDTH(WIDTH)) fifo_sync_src (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .data_i(src_data_i),
        .valid_i(src_valid_i),
        .ready_o(src_ready_sync)
    );

    // Synchronizer for source valid
    fifo_sync #(.WIDTH(1)) fifo_sync_src_valid (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .data_i(src_valid_i),
        .valid_i(1'b1),
        .ready_o(src_valid_sync)
    );

    // Synchronizer for destination ready
    fifo_sync #(.WIDTH(1)) fifo_sync_dst_ready (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .data_i(dst_ready_i),
        .valid_i(1'b1),
        .ready_o(dst_ready_sync)
    );

    // Synchronizer for destination valid
    fifo_sync #(.WIDTH(1)) fifo_sync_dst_valid (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .data_i(1'b0),
        .valid_i(dst_valid_sync),
        .ready_o(1'b1)
    );

    // Synchronizer for destination data
    fifo_sync #(.WIDTH(WIDTH)) fifo_sync_dst (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .data_i(dst_data_o),
        .valid_i(1'b0),
        .ready_o(1'b1)
    );

    // FIFO core logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
        end else begin
            if (src_valid_i && src_ready_sync && !full) begin
                fifo[wr_ptr] <= src_data_sync;
                wr_ptr <= wr_ptr + 1;
            end
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= 0;
        end else begin
            if (dst_valid_sync && dst_ready_i && !empty) begin
                rd_ptr <= rd_ptr + 1;
            end
        end
    end

    assign full = (wr_ptr == rd_ptr) && (src_valid_i && src_ready_sync);
    assign empty = (wr_ptr == rd_ptr) && !src_valid_i;

    assign src_ready_o = ~full;
    assign dst_data_o = fifo[rd_ptr];
    assign dst_valid_o = ~empty && dst_ready_sync;

endmodule

module fifo_sync #(
    parameter WIDTH = 8
)(
    input                  rst_ni,
    input                  clk_i,
    input  [WIDTH-1:0]     data_i,
    input                  valid_i,
    output                 ready_o
);

    logic [WIDTH-1:0] data_sync;
    logic valid_sync;
    logic ready_sync;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            data_sync <= 0;
            valid_sync <= 0;
        end else begin
            data_sync <= data_i;
            valid_sync <= valid_i;
        end
    end

    assign ready_o = valid_sync;

endmodule
