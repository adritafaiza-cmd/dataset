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

reg [WIDTH-1:0] mem [2**LOG_DEPTH-1:0];
reg [LOG_DEPTH-1:0] src_ptr, dst_ptr;
reg [LOG_DEPTH-1:0] src_ptr_gray, dst_ptr_gray;
reg [LOG_DEPTH-1:0] src_ptr_sync, dst_ptr_sync;
reg [WIDTH-1:0] dst_data_reg;
reg dst_valid_reg;

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        src_ptr <= 0;
        src_ptr_gray <= 0;
    end else begin
        if (src_valid_i && src_ready_o) begin
            mem[src_ptr] <= src_data_i;
            src_ptr <= src_ptr + 1;
            src_ptr_gray <= gray_encode(src_ptr);
        end
    end
end

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        src_ready_o <= 1'b0;
    end else begin
        src_ready_o <= (src_ptr != (2**LOG_DEPTH-1)) && (src_ptr_gray != dst_ptr_sync);
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        dst_ptr <= 0;
        dst_ptr_gray <= 0;
        dst_ptr_sync <= 0;
    end else begin
        if (dst_valid_o && dst_ready_i) begin
            dst_ptr <= dst_ptr + 1;
            dst_ptr_gray <= gray_encode(dst_ptr);
        end
        dst_ptr_sync <= src_ptr_gray;
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        dst_data_reg <= 0;
        dst_valid_reg <= 1'b0;
    end else begin
        if (dst_valid_o && dst_ready_i) begin
            dst_data_reg <= mem[dst_ptr];
        end
        dst_valid_reg <= (dst_ptr != dst_ptr_sync) && (dst_ptr != (2**LOG_DEPTH-1));
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        dst_data_o <= 0;
        dst_valid_o <= 1'b0;
    end else begin
        dst_data_o <= dst_data_reg;
        dst_valid_o <= dst_valid_reg;
    end
end

function [LOG_DEPTH-1:0] gray_encode;
input [LOG_DEPTH-1:0] bin;
begin
    gray_encode = bin ^ (bin >> 1);
end
endfunction

endmodule
