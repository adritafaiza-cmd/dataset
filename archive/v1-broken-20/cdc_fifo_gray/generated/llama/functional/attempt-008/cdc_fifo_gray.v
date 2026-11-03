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

reg [WIDTH-1:0] fifo [2**LOG_DEPTH-1:0];
reg [LOG_DEPTH-1:0] src_ptr, dst_ptr;
reg [LOG_DEPTH-1:0] src_ptr_gray, dst_ptr_gray;
reg [LOG_DEPTH-1:0] src_ptr_sync, dst_ptr_sync;
reg [WIDTH-1:0] dst_data;
reg dst_valid;

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        src_ptr <= 0;
        src_ptr_gray <= 0;
    end else if (src_valid_i && src_ready_o) begin
        src_ptr <= src_ptr + 1;
        src_ptr_gray <= src_ptr_gray + 1;
    end
end

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        src_ptr_sync <= 0;
    end else begin
        src_ptr_sync <= src_ptr_gray;
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        dst_ptr <= 0;
        dst_ptr_gray <= 0;
        dst_ptr_sync <= 0;
    end else if (dst_valid_o && dst_ready_i) begin
        dst_ptr <= dst_ptr + 1;
        dst_ptr_gray <= dst_ptr_gray + 1;
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        dst_data <= 0;
        dst_valid <= 0;
    end else if (dst_valid_o && dst_ready_i) begin
        dst_data <= fifo[dst_ptr];
        dst_valid <= 0;
    end else if (src_ptr_sync != dst_ptr_sync) begin
        dst_data <= fifo[dst_ptr];
        dst_valid <= 1;
    end
end

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        src_ready_o <= 0;
    end else if (src_valid_i && src_ready_o) begin
        fifo[src_ptr] <= src_data_i;
        src_ready_o <= (src_ptr != (2**LOG_DEPTH-1));
    end else begin
        src_ready_o <= (src_ptr != (2**LOG_DEPTH-1));
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        dst_data_o <= 0;
        dst_valid_o <= 0;
    end else begin
        dst_data_o <= dst_data;
        dst_valid_o <= dst_valid;
    end
end

endmodule
