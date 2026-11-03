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

    localparam FIFO_SIZE = 1 << LOG_DEPTH;
    localparam ADDR_WIDTH = LOG_DEPTH;

    // Internal signals for source FIFO
    reg [WIDTH-1:0] src_fifo [0:FIFO_SIZE-1];
    reg [ADDR_WIDTH:0] src_head;
    reg [ADDR_WIDTH:0] src_tail;
    reg src_full;
    reg src_empty;

    // Internal signals for destination FIFO
    reg [WIDTH-1:0] dst_fifo [0:FIFO_SIZE-1];
    reg [ADDR_WIDTH:0] dst_head;
    reg [ADDR_WIDTH:0] dst_tail;
    reg dst_full;
    reg dst_empty;

    // Source FIFO logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_head <= 0;
            src_tail <= 0;
            src_full <= 0;
            src_empty <= 1;
        end else begin
            if (src_valid_i && src_ready_o && !src_full) begin
                src_fifo[src_tail] <= src_data_i;
                src_tail <= (src_tail + 1) % FIFO_SIZE;
                if (src_head == src_tail) begin
                    src_full <= 1;
                end
                src_empty <= 0;
            end else if (src_ready_o && !src_empty) begin
                src_head <= (src_head + 1) % FIFO_SIZE;
                if (src_head == src_tail) begin
                    src_empty <= 1;
                end
                src_full <= 0;
            end
        end
    end

    // Destination FIFO logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_head <= 0;
            dst_tail <= 0;
            dst_full <= 0;
            dst_empty <= 1;
        end else begin
            if (src_valid_i && src_ready_o && !src_full && !dst_full) begin
                dst_fifo[dst_tail] <= src_fifo[src_tail];
                dst_tail <= (dst_tail + 1) % FIFO_SIZE;
                if (dst_head == dst_tail) begin
                    dst_full <= 1;
                end
                dst_empty <= 0;
            end else if (dst_ready_i && !dst_empty) begin
                dst_head <= (dst_head + 1) % FIFO_SIZE;
                if (dst_head == dst_tail) begin
                    dst_empty <= 1;
                end
                dst_full <= 0;
            end
        end
    end

    // Ready/valid logic for source
    assign src_ready_o = !src_full;

    // Ready/valid logic for destination
    assign dst_valid_o = !dst_empty;

endmodule
