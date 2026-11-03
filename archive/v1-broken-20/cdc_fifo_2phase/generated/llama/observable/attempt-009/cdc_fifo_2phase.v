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

reg [WIDTH-1:0] fifo_mem [2**LOG_DEPTH-1:0];
reg [LOG_DEPTH-1:0] src_ptr, dst_ptr;
reg [LOG_DEPTH-1:0] src_ptr_gray, dst_ptr_gray;
reg [LOG_DEPTH-1:0] src_ptr_gray_sync, dst_ptr_gray_sync;
reg [LOG_DEPTH-1:0] src_ptr_sync, dst_ptr_sync;
reg [WIDTH-1:0] dst_data_reg;
reg dst_valid_reg;

assign src_ready_o = (src_ptr + 1) != dst_ptr_sync;
assign dst_valid_o = dst_valid_reg;

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
        src_ptr <= 0;
        src_ptr_gray <= 0;
    end else begin
        if (src_valid_i && src_ready_o) begin
            src_ptr <= src_ptr + 1;
            src_ptr_gray <= src_ptr_gray + 1;
            fifo_mem[src_ptr] <= src_data_i;
        end
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
        dst_ptr <= 0;
        dst_ptr_gray <= 0;
        dst_data_reg <= 0;
        dst_valid_reg <= 0;
    end else begin
        if (dst_ready_i && dst_valid_reg) begin
            dst_ptr <= dst_ptr + 1;
            dst_ptr_gray <= dst_ptr_gray + 1;
            dst_valid_reg <= 0;
        end
        if (dst_ptr != src_ptr_sync) begin
            dst_data_reg <= fifo_mem[dst_ptr];
            dst_valid_reg <= 1;
        end
    end
end

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
        src_ptr_gray_sync <= 0;
    end else begin
        src_ptr_gray_sync <= src_ptr_gray;
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
        dst_ptr_gray_sync <= 0;
    end else begin
        dst_ptr_gray_sync <= dst_ptr_gray;
    end
end

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
        src_ptr_sync <= 0;
    end else begin
        src_ptr_sync <= src_ptr_gray_sync;
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
        dst_ptr_sync <= 0;
    end else begin
        dst_ptr_sync <= dst_ptr_gray_sync;
    end
end

assign dst_data_o = dst_data_reg;

endmodule
