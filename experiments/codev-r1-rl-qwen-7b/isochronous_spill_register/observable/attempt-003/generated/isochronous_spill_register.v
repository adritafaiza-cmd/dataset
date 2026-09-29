module isochronous_spill_register #(
    parameter WIDTH = 8
) (
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

    reg [WIDTH-1:0] mem [0:1];
    reg [1:0] wptr, rptr;

    // Synchronizers for pointers across clock domains
    reg [1:0] rptr_sync1, rptr_sync2;
    reg [1:0] wptr_sync1, wptr_sync2;

    // Synchronize read pointer to write clock domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            rptr_sync1 <= 2'b0;
            rptr_sync2 <= 2'b0;
        end else begin
            rptr_sync1 <= rptr;
            rptr_sync2 <= rptr_sync1;
        end
    end

    // Synchronize write pointer to read clock domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            wptr_sync1 <= 2'b0;
            wptr_sync2 <= 2'b0;
        end else begin
            wptr_sync1 <= wptr;
            wptr_sync2 <= wptr_sync1;
        end
    end

    // Calculate FIFO status
    wire [2:0] w_diff = wptr - rptr_sync2;
    wire [2:0] r_diff = wptr_sync2 - rptr;
    wire full = (w_diff >= 2);
    wire empty = (r_diff == 0);

    // Assign valid and ready signals
    assign src_ready_o = !full;
    assign dst_valid_o = !empty;

    // Write pointer and memory update
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wptr <= 2'b0;
        end else if (src_valid_i && src_ready_o) begin
            mem[wptr[0]] <= src_data_i;
            wptr <= wptr + 1;
        end
    end

    // Read pointer update
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rptr <= 2'b0;
        end else if (dst_ready_i && dst_valid_o) begin
            rptr <= rptr + 1;
        end
    end

    // Data output
    assign dst_data_o = mem[rptr[0]];

endmodule
