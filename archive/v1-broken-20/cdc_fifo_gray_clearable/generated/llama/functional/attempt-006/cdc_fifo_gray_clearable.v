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

reg [WIDTH-1:0] fifo[2**LOG_DEPTH-1:0];
reg [LOG_DEPTH-1:0] src_ptr, dst_ptr;
reg [LOG_DEPTH-1:0] src_ptr_gray, dst_ptr_gray;
reg [LOG_DEPTH-1:0] src_ptr_sync[SYNC_STAGES-1:0];
reg [LOG_DEPTH-1:0] dst_ptr_sync[SYNC_STAGES-1:0];
reg src_empty, src_full;
reg dst_empty, dst_full;
reg src_clear_pending, dst_clear_pending;
reg src_ready, dst_valid;

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        src_ptr <= 0;
        src_ptr_gray <= 0;
        src_empty <= 1;
        src_full <= 0;
        src_clear_pending <= 0;
    end else if (src_clear_i) begin
        src_ptr <= 0;
        src_ptr_gray <= 0;
        src_empty <= 1;
        src_full <= 0;
        src_clear_pending <= 1;
    end else if (src_valid_i && src_ready) begin
        if (src_empty) begin
            fifo[0] <= src_data_i;
            src_ptr <= 1;
            src_ptr_gray <= gray_encode(1);
            src_empty <= 0;
        end else if (src_full) begin
            // do nothing
        end else begin
            fifo[src_ptr] <= src_data_i;
            src_ptr <= src_ptr + 1;
            src_ptr_gray <= gray_encode(src_ptr + 1);
            src_full <= (src_ptr == (2**LOG_DEPTH - 1));
        end
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        dst_ptr <= 0;
        dst_ptr_gray <= 0;
        dst_empty <= 1;
        dst_full <= 0;
        dst_clear_pending <= 0;
        dst_valid <= 0;
    end else if (dst_clear_i) begin
        dst_ptr <= 0;
        dst_ptr_gray <= 0;
        dst_empty <= 1;
        dst_full <= 0;
        dst_clear_pending <= 1;
        dst_valid <= 0;
    end else if (dst_ready_i && dst_valid) begin
        if (dst_empty) begin
            // do nothing
        end else begin
            dst_ptr <= dst_ptr + 1;
            dst_ptr_gray <= gray_encode(dst_ptr + 1);
            dst_empty <= (dst_ptr == (2**LOG_DEPTH - 1));
            dst_valid <= 0;
        end
    end else if (!dst_empty) begin
        dst_valid <= 1;
    end
end

always @(posedge src_clk_i) begin
    src_ptr_sync[0] <= src_ptr_gray;
    for (genvar i = 1; i < SYNC_STAGES; i++) begin
        src_ptr_sync[i] <= src_ptr_sync[i-1];
    end
end

always @(posedge dst_clk_i) begin
    dst_ptr_sync[0] <= dst_ptr_gray;
    for (genvar i = 1; i < SYNC_STAGES; i++) begin
        dst_ptr_sync[i] <= dst_ptr_sync[i-1];
    end
end

assign src_ready = !src_full && !src_clear_pending;
assign dst_valid = !dst_empty && !dst_clear_pending;
assign src_clear_pending_o = src_clear_pending;
assign dst_clear_pending_o = dst_clear_pending;

assign dst_data_o = fifo[dst_ptr_sync[SYNC_STAGES-1]];

function [LOG_DEPTH-1:0] gray_encode;
input [LOG_DEPTH-1:0] bin;
begin
    gray_encode = bin ^ (bin >> 1);
end
endfunction

endmodule
