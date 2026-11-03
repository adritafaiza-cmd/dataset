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

reg [WIDTH-1:0] src_fifo [2**LOG_DEPTH-1:0];
reg [LOG_DEPTH-1:0] src_ptr, src_ptr_gray, src_ptr_bin;
reg [LOG_DEPTH-1:0] dst_ptr, dst_ptr_gray, dst_ptr_bin;
reg [WIDTH-1:0] dst_data_reg;
reg dst_valid_reg;
reg src_clear_pending_reg;
reg dst_clear_pending_reg;

assign src_clear_pending_o = src_clear_pending_reg;
assign dst_clear_pending_o = dst_clear_pending_reg;

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
        src_ptr <= 0;
        src_ptr_gray <= 0;
        src_clear_pending_reg <= 0;
    end else if (src_clear_i) begin
        src_ptr <= 0;
        src_ptr_gray <= 0;
        src_clear_pending_reg <= 0;
    end else if (src_valid_i && src_ready_o) begin
        src_fifo[src_ptr] <= src_data_i;
        src_ptr <= src_ptr + 1;
        src_ptr_gray <= gray_encode(src_ptr);
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
        dst_ptr <= 0;
        dst_ptr_gray <= 0;
        dst_ptr_bin <= 0;
        dst_clear_pending_reg <= 0;
        dst_valid_reg <= 0;
        dst_data_reg <= 0;
    end else if (dst_clear_i) begin
        dst_ptr <= 0;
        dst_ptr_gray <= 0;
        dst_ptr_bin <= 0;
        dst_clear_pending_reg <= 0;
        dst_valid_reg <= 0;
        dst_data_reg <= 0;
    end else begin
        dst_ptr_bin <= bin_from_gray(dst_ptr_gray);
        if (dst_valid_reg && dst_ready_i) begin
            dst_valid_reg <= 0;
            dst_ptr <= dst_ptr + 1;
            dst_ptr_gray <= gray_encode(dst_ptr);
        end else if (dst_ptr_bin != src_ptr_bin) begin
            dst_data_reg <= src_fifo[dst_ptr_bin];
            dst_valid_reg <= 1;
        end
    end
end

assign src_ready_o = (src_ptr != (2**LOG_DEPTH-1)) && (!src_clear_pending_reg || src_clear_i);
assign dst_valid_o = dst_valid_reg;
assign dst_data_o = dst_data_reg;

always @(posedge src_clk_i) begin
    src_clear_pending_reg <= (src_clear_i && (src_ptr != 0)) ? 1 : 0;
end

always @(posedge dst_clk_i) begin
    dst_clear_pending_reg <= (dst_clear_i && (dst_ptr != 0)) ? 1 : 0;
end

reg [LOG_DEPTH-1:0] src_ptr_sync [SYNC_STAGES-1:0];
reg [LOG_DEPTH-1:0] dst_ptr_sync [SYNC_STAGES-1:0];

always @(posedge dst_clk_i) begin
    src_ptr_sync[0] <= src_ptr_gray;
    for (genvar i = 1; i < SYNC_STAGES; i++) begin
        src_ptr_sync[i] <= src_ptr_sync[i-1];
    end
end

always @(posedge src_clk_i) begin
    dst_ptr_sync[0] <= dst_ptr_gray;
    for (genvar i = 1; i < SYNC_STAGES; i++) begin
        dst_ptr_sync[i] <= dst_ptr_sync[i-1];
    end
end

assign src_ptr_bin = bin_from_gray(src_ptr_sync[SYNC_STAGES-1]);
assign dst_ptr_bin = bin_from_gray(dst_ptr_sync[SYNC_STAGES-1]);

function [LOG_DEPTH-1:0] gray_encode;
input [LOG_DEPTH-1:0] bin;
begin
    gray_encode = bin ^ (bin >> 1);
end
endfunction

function [LOG_DEPTH-1:0] bin_from_gray;
input [LOG_DEPTH-1:0] gray;
begin
    bin_from_gray = gray ^ (gray >> 1);
end
endfunction

endmodule
