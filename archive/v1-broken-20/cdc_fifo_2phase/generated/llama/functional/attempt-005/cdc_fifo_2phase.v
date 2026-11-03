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

reg [WIDTH-1:0] fifo [2**LOG_DEPTH-1:0];
reg [LOG_DEPTH-1:0] wr_ptr, rd_ptr;
reg [LOG_DEPTH-1:0] wr_ptr_gray, rd_ptr_gray;
reg [LOG_DEPTH-1:0] wr_ptr_gray_sync;
reg [WIDTH-1:0] dst_data_reg;
reg dst_valid_reg;

assign src_ready_o = (wr_ptr_gray_sync != rd_ptr_gray) && (wr_ptr_gray_sync != (rd_ptr_gray + 1));

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
        wr_ptr <= 0;
        wr_ptr_gray <= 0;
    end else if (src_valid_i && src_ready_o) begin
        fifo[wr_ptr] <= src_data_i;
        wr_ptr <= wr_ptr + 1;
        wr_ptr_gray <= (wr_ptr + 1) ^ ((wr_ptr + 1) >> 1);
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
        rd_ptr <= 0;
        rd_ptr_gray <= 0;
        dst_data_reg <= 0;
        dst_valid_reg <= 0;
    end else begin
        if (dst_ready_i && dst_valid_reg) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= (rd_ptr + 1) ^ ((rd_ptr + 1) >> 1);
            dst_valid_reg <= 0;
        end
        if (wr_ptr_gray_sync != rd_ptr_gray) begin
            dst_data_reg <= fifo[rd_ptr];
            dst_valid_reg <= 1;
        end
    end
end

always @(posedge dst_clk_i) begin
    wr_ptr_gray_sync <= wr_ptr_gray;
end

always @(posedge dst_clk_i) begin
    dst_data_o <= dst_data_reg;
    dst_valid_o <= dst_valid_reg;
end

endmodule
