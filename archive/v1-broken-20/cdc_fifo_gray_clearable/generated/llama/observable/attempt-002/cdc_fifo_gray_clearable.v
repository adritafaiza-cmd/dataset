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
reg [LOG_DEPTH-1:0] src_wr_ptr, src_rd_ptr;
reg [LOG_DEPTH-1:0] src_wr_ptr_gray, src_rd_ptr_gray;
reg [LOG_DEPTH:0] src_fifo_count;
reg src_clear_pending;

reg [WIDTH-1:0] dst_fifo [2**LOG_DEPTH-1:0];
reg [LOG_DEPTH-1:0] dst_wr_ptr, dst_rd_ptr;
reg [LOG_DEPTH-1:0] dst_wr_ptr_gray, dst_rd_ptr_gray;
reg [LOG_DEPTH:0] dst_fifo_count;
reg dst_clear_pending;

reg [WIDTH-1:0] dst_data_reg;
reg dst_valid_reg;

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        src_wr_ptr <= 0;
        src_rd_ptr <= 0;
        src_wr_ptr_gray <= 0;
        src_rd_ptr_gray <= 0;
        src_fifo_count <= 0;
        src_clear_pending <= 0;
    end else if (src_clear_i) begin
        src_wr_ptr <= 0;
        src_rd_ptr <= 0;
        src_wr_ptr_gray <= 0;
        src_rd_ptr_gray <= 0;
        src_fifo_count <= 0;
        src_clear_pending <= 0;
    end else begin
        if (src_valid_i && src_ready_o) begin
            src_fifo[src_wr_ptr] <= src_data_i;
            src_wr_ptr <= src_wr_ptr + 1;
            src_fifo_count <= src_fifo_count + 1;
        end
        if (src_clear_pending) begin
            src_clear_pending <= 0;
        end
    end
end

always @(posedge src_clk_i) begin
    src_wr_ptr_gray <= gray_encode(src_wr_ptr);
    src_rd_ptr_gray <= gray_encode(src_rd_ptr);
end

assign src_ready_o = (src_fifo_count < 2**LOG_DEPTH) &&!src_clear_i;
assign src_clear_pending_o = src_clear_pending;

reg [LOG_DEPTH-1:0] src_wr_ptr_gray_sync [SYNC_STAGES-1:0];
reg [LOG_DEPTH-1:0] src_rd_ptr_gray_sync [SYNC_STAGES-1:0];

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        src_wr_ptr_gray_sync <= '{default: 0};
        src_rd_ptr_gray_sync <= '{default: 0};
    end else begin
        src_wr_ptr_gray_sync[0] <= src_wr_ptr_gray;
        src_rd_ptr_gray_sync[0] <= src_rd_ptr_gray;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            src_wr_ptr_gray_sync[i] <= src_wr_ptr_gray_sync[i-1];
            src_rd_ptr_gray_sync[i] <= src_rd_ptr_gray_sync[i-1];
        end
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        dst_wr_ptr <= 0;
        dst_rd_ptr <= 0;
        dst_wr_ptr_gray <= 0;
        dst_rd_ptr_gray <= 0;
        dst_fifo_count <= 0;
        dst_clear_pending <= 0;
    end else if (dst_clear_i) begin
        dst_wr_ptr <= 0;
        dst_rd_ptr <= 0;
        dst_wr_ptr_gray <= 0;
        dst_rd_ptr_gray <= 0;
        dst_fifo_count <= 0;
        dst_clear_pending <= 0;
    end else begin
        if (src_wr_ptr_gray_sync[SYNC_STAGES-1]!= src_rd_ptr_gray_sync[SYNC_STAGES-1]) begin
            dst_fifo[dst_wr_ptr] <= src_fifo[gray_decode(src_wr_ptr_gray_sync[SYNC_STAGES-1])];
            dst_wr_ptr <= dst_wr_ptr + 1;
            dst_fifo_count <= dst_fifo_count + 1;
        end
        if (dst_clear_pending) begin
            dst_clear_pending <= 0;
        end
    end
end

always @(posedge dst_clk_i) begin
    dst_wr_ptr_gray <= gray_encode(dst_wr_ptr);
    dst_rd_ptr_gray <= gray_encode(dst_rd_ptr);
end

always @(posedge dst_clk_i) begin
    if (dst_ready_i && dst_valid_reg) begin
        dst_rd_ptr <= dst_rd_ptr + 1;
        dst_fifo_count <= dst_fifo_count - 1;
    end
    if (dst_clear_i) begin
        dst_rd_ptr <= 0;
        dst_fifo_count <= 0;
    end
end

always @(posedge dst_clk_i) begin
    dst_data_reg <= dst_fifo[dst_rd_ptr];
    dst_valid_reg <= (dst_fifo_count > 0);
end

assign dst_data_o = dst_data_reg;
assign dst_valid_o = dst_valid_reg;
assign dst_clear_pending_o = dst_clear_pending;

function [LOG_DEPTH-1:0] gray_encode;
input [LOG_DEPTH-1:0] bin;
begin
    gray_encode = bin ^ (bin >> 1);
end
endfunction

function [LOG_DEPTH-1:0] gray_decode;
input [LOG_DEPTH-1:0] gray;
reg [LOG_DEPTH:0] mask;
begin
    mask = 1;
    gray_decode = gray;
    for (int i = 1; i < LOG_DEPTH; i++) begin
        mask = {mask, 1'b0};
        gray_decode = gray_decode ^ (gray >> i);
    end
end
endfunction

endmodule
