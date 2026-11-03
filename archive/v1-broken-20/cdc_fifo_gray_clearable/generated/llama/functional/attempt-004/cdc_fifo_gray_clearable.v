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

reg [WIDTH-1:0] fifo [2**LOG_DEPTH-1:0];
reg [LOG_DEPTH-1:0] src_ptr, dst_ptr;
reg [LOG_DEPTH-1:0] src_ptr_gray, dst_ptr_gray;
reg [LOG_DEPTH-1:0] src_ptr_sync, dst_ptr_sync;
reg [WIDTH-1:0] src_data_sync;
reg src_valid_sync, dst_valid_sync;
reg src_ready_sync, dst_ready_sync;
reg src_clear_sync, dst_clear_sync;
reg src_clear_pending, dst_clear_pending;

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
        src_ptr <= 0;
        src_ptr_gray <= 0;
        src_clear_pending <= 0;
        src_ready_sync <= 0;
    end else if (src_clear_i) begin
        src_ptr <= 0;
        src_ptr_gray <= 0;
        src_clear_pending <= 1;
        src_ready_sync <= 0;
    end else if (src_valid_i && src_ready_sync) begin
        fifo[src_ptr] <= src_data_i;
        src_ptr <= src_ptr + 1;
        src_ptr_gray <= gray_encode(src_ptr);
        src_clear_pending <= 0;
    end else if (src_clear_i) begin
        src_clear_pending <= 1;
    end else begin
        src_clear_pending <= 0;
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
        dst_ptr <= 0;
        dst_ptr_gray <= 0;
        dst_clear_pending <= 0;
        dst_valid_sync <= 0;
    end else if (dst_clear_i) begin
        dst_ptr <= 0;
        dst_ptr_gray <= 0;
        dst_clear_pending <= 1;
        dst_valid_sync <= 0;
    end else if (dst_ready_i && dst_valid_sync) begin
        dst_ptr <= dst_ptr + 1;
        dst_ptr_gray <= gray_encode(dst_ptr);
        dst_clear_pending <= 0;
    end else if (dst_clear_i) begin
        dst_clear_pending <= 1;
    end else begin
        dst_clear_pending <= 0;
    end
end

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
        src_ptr_sync <= 0;
        src_valid_sync <= 0;
        src_data_sync <= 0;
        src_ready_sync <= 0;
    end else if (src_clear_i) begin
        src_ptr_sync <= 0;
        src_valid_sync <= 0;
        src_data_sync <= 0;
        src_ready_sync <= 0;
    end else begin
        src_ptr_sync <= src_ptr_gray;
        src_valid_sync <= src_valid_i;
        src_data_sync <= src_data_i;
        src_ready_sync <= (src_ptr != (2**LOG_DEPTH-1));
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
        dst_ptr_sync <= 0;
        dst_valid_sync <= 0;
        dst_data_o <= 0;
        dst_valid_o <= 0;
    end else if (dst_clear_i) begin
        dst_ptr_sync <= 0;
        dst_valid_sync <= 0;
        dst_data_o <= 0;
        dst_valid_o <= 0;
    end else begin
        dst_ptr_sync <= dst_ptr_gray;
        dst_valid_sync <= (dst_ptr != src_ptr_sync);
        dst_data_o <= fifo[dst_ptr];
        dst_valid_o <= dst_valid_sync;
    end
end

assign src_ready_o = src_ready_sync;
assign dst_clear_pending_o = dst_clear_pending;
assign src_clear_pending_o = src_clear_pending;

function [LOG_DEPTH-1:0] gray_encode;
input [LOG_DEPTH-1:0] bin;
begin
    gray_encode = bin ^ (bin >> 1);
end
endfunction

endmodule
