module isochronous_spill_register #(
    parameter WIDTH = 8
)(
    input              src_clk_i,
    input              src_rst_ni,
    input              src_valid_i,
    output             src_ready_o,
    input  [WIDTH-1:0] src_data_i,
    input              dst_clk_i,
    input              dst_rst_ni,
    output             dst_valid_o,
    input              dst_ready_i,
    output [WIDTH-1:0] dst_data_o
);

reg [WIDTH-1:0] buffer[1:0];
reg [1:0]       valid;
reg             src_ready;
reg             dst_valid;

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
        valid[0] <= 1'b0;
        valid[1] <= 1'b0;
        buffer[0] <= {WIDTH{1'b0}};
        buffer[1] <= {WIDTH{1'b0}};
    end else if (src_valid_i && src_ready) begin
        buffer[0] <= src_data_i;
        valid[0] <= 1'b1;
    end else if (valid[0] && src_ready) begin
        buffer[1] <= buffer[0];
        valid[1] <= valid[0];
        valid[0] <= 1'b0;
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
        dst_valid <= 1'b0;
    end else if (valid[1] && dst_ready_i) begin
        dst_valid <= 1'b0;
    end else if (valid[0] && ~valid[1] && dst_ready_i) begin
        dst_valid <= 1'b1;
    end
end

assign src_ready_o = (~valid[0] && ~valid[1]) || (valid[0] && dst_ready_i);
assign dst_valid_o = dst_valid;
assign dst_data_o = buffer[1];

endmodule
