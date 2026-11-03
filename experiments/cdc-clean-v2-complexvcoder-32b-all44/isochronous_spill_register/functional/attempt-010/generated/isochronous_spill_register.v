module isochronous_spill_register #(
    parameter WIDTH = 8
)(
    input              src_clk_i,
    input              src_rst_ni,
    input              src_valid_i,
    output             src_ready_o,
    input  [WIDTH-1:0] src_data_i,
    input              dst_clk_i,
    input              dst_rst_ni,
    output             dst_valid_o,
    input              dst_ready_i,
    output [WIDTH-1:0] dst_data_o
);

    // Internal signals
    reg                src_fifo_full;
    reg                src_fifo_almost_full;
    reg                src_fifo_empty;
    reg  [WIDTH-1:0]   src_fifo_data_out;
    reg                src_fifo_valid_out;
    reg                dst_fifo_full;
    reg                dst_fifo_almost_full;
    reg                dst_fifo_empty;
    reg  [WIDTH-1:0]   dst_fifo_data_out;
    reg                dst_fifo_valid_out;
    reg                src_fifo_push;
    reg                src_fifo_pop;
    reg                dst_fifo_push;
    reg                dst_fifo_pop;

    // Source FIFO
    reg  [WIDTH-1:0]   src_fifo [1:0];
    reg  [1:0]         src_fifo_head;
    reg  [1:0]         src_fifo_tail;
    reg  [1:0]         src_fifo_count;

    // Source FIFO operations
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_fifo_head <= 2'b00;
            src_fifo_tail <= 2'b00;
            src_fifo_count <= 2'b00;
            src_fifo_full <= 1'b0;
            src_fifo_almost_full <= 1'b0;
            src_fifo_empty <= 1'b1;
        end else begin
            if (src_fifo_push) begin
                src_fifo[src_fifo_head] <= src_data_i;
                src_fifo_head <= src_fifo_head + 1;
                src_fifo_count <= src_fifo_count + 1;
            end else if (src_fifo_pop) begin
                src_fifo_tail <= src_fifo_tail + 1;
                src_fifo_count <= src_fifo_count - 1;
            end

            src_fifo_full <= (src_fifo_count == 2);
            src_fifo_almost_full <= (src_fifo_count == 2);
            src_fifo_empty <= (src_fifo_count == 0);
        end
    end

    assign src_fifo_data_out = src_fifo[src_fifo_tail];
    assign src_fifo_valid_out = !src_fifo_empty;

    // Source FIFO control logic
    always @(*) begin
        src_fifo_push = src_valid_i & !src_fifo_almost_full;
        src_fifo_pop = !src_fifo_empty & dst_fifo_push;
        src_ready_o = !src_fifo_almost_full;
    end

    // Destination FIFO
    reg  [WIDTH-1:0]   dst_fifo [1:0];
    reg  [1:0]         dst_fifo_head;
    reg  [1:0]         dst_fifo_tail;
    reg  [1:0]         dst_fifo_count;

    // Destination FIFO operations
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_fifo_head <= 2'b00;
            dst_fifo_tail <= 2'b00;
            dst_fifo_count <= 2'b00;
            dst_fifo_full <= 1'b0;
            dst_fifo_almost_full <= 1'b0;
            dst_fifo_empty <= 1'b1;
        end else begin
            if (dst_fifo_push) begin
                dst_fifo[dst_fifo_head] <= src_fifo_data_out;
                dst_fifo_head <= dst_fifo_head + 1;
                dst_fifo_count <= dst_fifo_count + 1;
            end else if (dst_fifo_pop) begin
                dst_fifo_tail <= dst_fifo_tail + 1;
                dst_fifo_count <= dst_fifo_count - 1;
            end

            dst_fifo_full <= (dst_fifo_count == 2);
            dst_fifo_almost_full <= (dst_fifo_count == 2);
            dst_fifo_empty <= (dst_fifo_count == 0);
        end
    end

    assign dst_fifo_data_out = dst_fifo[dst_fifo_tail];
    assign dst_fifo_valid_out = !dst_fifo_empty;

    // Destination FIFO control logic
    always @(*) begin
        dst_fifo_push = !dst_fifo_full & src_fifo_pop;
        dst_fifo_pop = dst_fifo_valid_out & dst_ready_i;
        dst_valid_o = dst_fifo_valid_out;
        dst_data_o = dst_fifo_data_out;
    end

endmodule
