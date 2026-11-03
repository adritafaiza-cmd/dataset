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

reg [WIDTH-1:0] fifo_ram [2**LOG_DEPTH-1:0];
reg [LOG_DEPTH-1:0] src_ptr, dst_ptr;
reg [LOG_DEPTH-1:0] src_ptr_gray, dst_ptr_gray;
reg [LOG_DEPTH-1:0] src_ptr_sync, dst_ptr_sync;
reg [WIDTH-1:0] dst_data_reg;
reg src_valid_reg, dst_valid_reg;
reg src_ready_reg, dst_ready_reg;
reg src_clear_pending_reg, dst_clear_pending_reg;

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
        src_ptr <= 0;
        src_ptr_gray <= 0;
        src_clear_pending_reg <= 0;
        src_ready_reg <= 0;
    end else if (src_clear_i) begin
        src_ptr <= 0;
        src_ptr_gray <= 0;
        src_clear_pending_reg <= 1;
        src_ready_reg <= 0;
    end else if (src_valid_i && src_ready_reg) begin
        fifo_ram[src_ptr] <= src_data_i;
        src_ptr <= src_ptr + 1;
        src_ptr_gray <= gray_encode(src_ptr);
        src_ready_reg <= (src_ptr != (2**LOG_DEPTH-1));
    end else if (src_clear_pending_reg) begin
        src_clear_pending_reg <= 0;
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
        dst_ptr <= 0;
        dst_ptr_gray <= 0;
        dst_ptr_sync <= 0;
        dst_clear_pending_reg <= 0;
        dst_valid_reg <= 0;
        dst_data_reg <= 0;
    end else if (dst_clear_i) begin
        dst_ptr <= 0;
        dst_ptr_gray <= 0;
        dst_ptr_sync <= 0;
        dst_clear_pending_reg <= 1;
        dst_valid_reg <= 0;
    end else if (dst_ready_i && dst_valid_reg) begin
        dst_ptr <= dst_ptr + 1;
        dst_ptr_gray <= gray_encode(dst_ptr);
        dst_valid_reg <= (dst_ptr != (2**LOG_DEPTH-1));
    end else if (dst_clear_pending_reg) begin
        dst_clear_pending_reg <= 0;
    end
end

always @(posedge dst_clk_i) begin
    if (dst_valid_reg && dst_ready_i) begin
        dst_data_reg <= fifo_ram[dst_ptr_sync];
    end
end

always @(posedge src_clk_i) begin
    src_clear_pending_o <= src_clear_pending_reg;
    src_ready_o <= src_ready_reg;
end

always @(posedge dst_clk_i) begin
    dst_clear_pending_o <= dst_clear_pending_reg;
    dst_data_o <= dst_data_reg;
    dst_valid_o <= dst_valid_reg;
end

always @(posedge src_clk_i) begin
    src_ptr_sync <= src_ptr_gray;
end

always @(posedge dst_clk_i) begin
    dst_ptr_sync <= dst_ptr_gray;
    dst_valid_reg <= (dst_ptr_sync != src_ptr_sync) && (dst_ptr_sync != 0);
end

function [LOG_DEPTH-1:0] gray_encode;
input [LOG_DEPTH-1:0] bin;
begin
    gray_encode = (bin >> 1) ^ bin;
end
endfunction

endmodule
