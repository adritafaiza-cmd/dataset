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
reg [LOG_DEPTH-1:0] src_ptr;
reg [LOG_DEPTH-1:0] src_ptr_gray;
reg [LOG_DEPTH-1:0] src_ptr_sync [SYNC_STAGES-1:0];
reg [WIDTH-1:0] dst_fifo [2**LOG_DEPTH-1:0];
reg [LOG_DEPTH-1:0] dst_ptr;
reg [LOG_DEPTH-1:0] dst_ptr_gray;
reg [LOG_DEPTH-1:0] dst_ptr_sync [SYNC_STAGES-1:0];
reg src_empty;
reg src_full;
reg dst_empty;
reg dst_full;
reg src_clear_pending;
reg dst_clear_pending;

assign src_clear_pending_o = src_clear_pending;
assign dst_clear_pending_o = dst_clear_pending;

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
        src_ptr <= 0;
        src_ptr_gray <= 0;
        src_clear_pending <= 0;
        src_empty <= 1;
        src_full <= 0;
    end else if (src_clear_i) begin
        src_ptr <= 0;
        src_ptr_gray <= 0;
        src_clear_pending <= 0;
        src_empty <= 1;
        src_full <= 0;
    end else begin
        if (src_valid_i && src_ready_o) begin
            src_fifo[src_ptr] <= src_data_i;
            src_ptr <= src_ptr + 1;
            if (src_ptr == 2**LOG_DEPTH-1) begin
                src_ptr <= 0;
            end
            src_full <= (src_ptr == 2**LOG_DEPTH-1);
        end
        src_empty <= (src_ptr == 0);
        if (src_valid_i && ~src_ready_o) begin
            src_clear_pending <= 1;
        end else if (~src_valid_i && src_ready_o) begin
            src_clear_pending <= 0;
        end
    end
end

always @(posedge src_clk_i) begin
    src_ptr_gray <= gray_encode(src_ptr);
end

always @(posedge src_clk_i) begin
    src_ptr_sync[0] <= src_ptr_gray;
    for (genvar i = 1; i < SYNC_STAGES; i++) begin
        src_ptr_sync[i] <= src_ptr_sync[i-1];
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
        dst_ptr <= 0;
        dst_ptr_gray <= 0;
        dst_clear_pending <= 0;
        dst_empty <= 1;
        dst_full <= 0;
    end else if (dst_clear_i) begin
        dst_ptr <= 0;
        dst_ptr_gray <= 0;
        dst_clear_pending <= 0;
        dst_empty <= 1;
        dst_full <= 0;
    end else begin
        if (dst_valid_o && dst_ready_i) begin
            dst_ptr <= dst_ptr + 1;
            if (dst_ptr == 2**LOG_DEPTH-1) begin
                dst_ptr <= 0;
            end
            dst_empty <= (dst_ptr == 0);
        end
        dst_full <= (dst_ptr == 2**LOG_DEPTH-1);
        if (~dst_valid_o && dst_ready_i) begin
            dst_clear_pending <= 1;
        end else if (dst_valid_o && ~dst_ready_i) begin
            dst_clear_pending <= 0;
        end
    end
end

always @(posedge dst_clk_i) begin
    dst_ptr_gray <= gray_encode(dst_ptr);
end

always @(posedge dst_clk_i) begin
    dst_ptr_sync[0] <= dst_ptr_gray;
    for (genvar i = 1; i < SYNC_STAGES; i++) begin
        dst_ptr_sync[i] <= dst_ptr_sync[i-1];
    end
end

always @(posedge src_clk_i) begin
    if (src_valid_i && src_ready_o) begin
        src_fifo[src_ptr] <= src_data_i;
    end
end

always @(posedge dst_clk_i) begin
    if (dst_valid_o && dst_ready_i) begin
        dst_data_o <= dst_fifo[dst_ptr_sync[SYNC_STAGES-1]];
    end
end

assign src_ready_o = ~src_full || (src_empty && ~src_clear_pending);
assign dst_valid_o = ~dst_empty && ~dst_clear_pending;

function [LOG_DEPTH-1:0] gray_encode;
input [LOG_DEPTH-1:0] bin;
begin
    gray_encode = bin ^ (bin >> 1);
end
endfunction

endmodule
