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

reg [WIDTH-1:0] mem [2**LOG_DEPTH-1:0];
reg [LOG_DEPTH-1:0] src_ptr, dst_ptr;
reg [LOG_DEPTH-1:0] src_ptr_gray, dst_ptr_gray;
reg [LOG_DEPTH-1:0] src_ptr_gray_sync, dst_ptr_gray_sync;
reg [LOG_DEPTH:0] src_cnt, dst_cnt;
reg src_valid_sync, dst_valid_sync;
reg src_ready_sync, dst_ready_sync;
reg [WIDTH-1:0] dst_data_sync;

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
        src_ptr <= 0;
        src_cnt <= 0;
    end else if (src_valid_i && src_ready_o) begin
        mem[src_ptr] <= src_data_i;
        src_ptr <= src_ptr + 1;
        src_cnt <= src_cnt + 1;
    end else if (src_cnt > 0 && ~src_valid_i && src_ready_o) begin
        src_cnt <= src_cnt - 1;
    end
end

always @(posedge src_clk_i) begin
    src_ptr_gray <= src_ptr;
    src_valid_sync <= src_valid_i;
    src_ready_sync <= (src_cnt < 2**LOG_DEPTH);
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
        dst_ptr <= 0;
        dst_cnt <= 0;
    end else if (dst_valid_o && dst_ready_i) begin
        dst_ptr <= dst_ptr + 1;
        dst_cnt <= dst_cnt - 1;
    end else if (dst_cnt < 2**LOG_DEPTH && ~dst_valid_o && dst_ready_i) begin
        dst_cnt <= dst_cnt + 1;
    end
end

always @(posedge dst_clk_i) begin
    dst_ptr_gray <= dst_ptr;
    dst_valid_sync <= (dst_cnt > 0);
    dst_ready_sync <= (dst_cnt < 2**LOG_DEPTH);
    if (dst_valid_o && dst_ready_i) begin
        dst_data_sync <= mem[dst_ptr];
    end
end

always @(posedge src_clk_i) begin
    src_ptr_gray_sync <= src_ptr_gray;
end

always @(posedge dst_clk_i) begin
    dst_ptr_gray_sync <= dst_ptr_gray;
end

assign src_ready_o = src_ready_sync;
assign dst_valid_o = dst_valid_sync;
assign dst_data_o = dst_data_sync;

endmodule
