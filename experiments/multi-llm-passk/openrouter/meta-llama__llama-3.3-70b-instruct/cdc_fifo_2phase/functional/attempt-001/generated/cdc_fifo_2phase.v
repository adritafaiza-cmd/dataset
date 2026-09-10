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
reg [LOG_DEPTH-1:0] wr_ptr, rd_ptr;
reg [LOG_DEPTH:0] cnt;

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
        wr_ptr <= 0;
        cnt <= 0;
    end else if (src_valid_i && src_ready_o) begin
        mem[wr_ptr] <= src_data_i;
        wr_ptr <= wr_ptr + 1;
        cnt <= cnt + 1;
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
        rd_ptr <= 0;
        cnt <= 0;
    end else if (dst_valid_o && dst_ready_i) begin
        rd_ptr <= rd_ptr + 1;
        cnt <= cnt - 1;
    end
end

assign src_ready_o = (cnt < 2**LOG_DEPTH);
assign dst_valid_o = (cnt > 0);
assign dst_data_o = mem[rd_ptr];

endmodule
