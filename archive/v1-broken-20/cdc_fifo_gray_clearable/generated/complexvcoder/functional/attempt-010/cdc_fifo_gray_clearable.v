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

    localparam FIFO_SIZE = 1 << LOG_DEPTH;

    // Internal signals
    logic [WIDTH-1:0] fifo [0:FIFO_SIZE-1];
    logic [LOG_DEPTH-1:0] head, tail;
    logic [LOG_DEPTH:0] count;
    logic src_clear_done, dst_clear_done;

    // Clear control
    assign src_clear_pending_o = ~src_clear_done;
    assign dst_clear_pending_o = ~dst_clear_done;

    // Source-side logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            head <= 0;
            tail <= 0;
            count <= 0;
            src_clear_done <= 1;
        end else begin
            if (src_clear_i && !src_clear_done) begin
                head <= 0;
                tail <= 0;
                count <= 0;
                src_clear_done <= 0;
            end else if (src_valid_i && src_ready_o && !src_clear_i) begin
                fifo[head] <= src_data_i;
                head <= (head + 1) % FIFO_SIZE;
                count <= count + 1;
            end
        end
    end

    // Destination-side logic
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            head <= 0;
            tail <= 0;
            count <= 0;
            dst_clear_done <= 1;
        end else begin
            if (dst_clear_i && !dst_clear_done) begin
                head <= 0;
                tail <= 0;
                count <= 0;
                dst_clear_done <= 0;
            end else if (count > 0 && dst_ready_i && !dst_clear_i) begin
                tail <= (tail + 1) % FIFO_SIZE;
                count <= count - 1;
            end
        end
    end

    // Output logic
    assign src_ready_o = count < FIFO_SIZE;
    assign dst_data_o = fifo[tail];
    assign dst_valid_o = count > 0;

    // Synchronization
    logic [WIDTH-1:0] sync_fifo [0:FIFO_SIZE-1];
    logic [LOG_DEPTH-1:0] sync_head, sync_tail;
    logic [LOG_DEPTH:0] sync_count;

    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            sync_head <= 0;
            sync_tail <= 0;
            sync_count <= 0;
        end else begin
            if (src_clear_i || src_clear_done) begin
                sync_head <= 0;
                sync_tail <= 0;
                sync_count <= 0;
            end else if (src_valid_i && src_ready_o) begin
                sync_fifo[sync_head] <= src_data_i;
                sync_head <= (sync_head + 1) % FIFO_SIZE;
                sync_count <= sync_count + 1;
            end
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            sync_head <= 0;
            sync_tail <= 0;
            sync_count <= 0;
        end else begin
            if (dst_clear_i || dst_clear_done) begin
                sync_head <= 0;
                sync_tail <= 0;
                sync_count <= 0;
            end else if (sync_count > 0 && dst_ready_i) begin
                sync_tail <= (sync_tail + 1) % FIFO_SIZE;
                sync_count <= sync_count - 1;
            end
        end
    end

endmodule
