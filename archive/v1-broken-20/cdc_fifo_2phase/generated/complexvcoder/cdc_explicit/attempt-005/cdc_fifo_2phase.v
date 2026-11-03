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

    localparam DEPTH = 2**LOG_DEPTH;
    localparam ADDR_WIDTH = LOG_DEPTH;

    // FIFO for source domain
    logic [WIDTH-1:0] src_fifo [0:DEPTH-1];
    logic [ADDR_WIDTH:0] src_head, src_tail;
    logic src_full, src_empty;

    // FIFO for destination domain
    logic [WIDTH-1:0] dst_fifo [0:DEPTH-1];
    logic [ADDR_WIDTH:0] dst_head, dst_tail;
    logic dst_full, dst_empty;

    // Source domain logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_head <= 0;
            src_tail <= 0;
        end else begin
            if (src_valid_i && src_ready_o && !src_full) begin
                src_fifo[src_head] <= src_data_i;
                src_head <= src_head + 1;
            end
        end
    end

    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_full <= 0;
        end else begin
            src_full <= (src_head + 1 == src_tail);
        end
    end

    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_empty <= 1;
        end else begin
            src_empty <= (src_head == src_tail);
        end
    end

    assign src_ready_o = !src_full;

    // Destination domain logic
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_tail <= 0;
        end else begin
            if (dst_ready_i && dst_valid_o && !dst_full) begin
                dst_tail <= dst_tail + 1;
            end
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_full <= 0;
        end else begin
            dst_full <= (dst_tail + 1 == dst_head);
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_empty <= 1;
        end else begin
            dst_empty <= (dst_tail == dst_head);
        end
    end

    assign dst_data_o = dst_fifo[dst_tail];
    assign dst_valid_o = !dst_empty;

endmodule
