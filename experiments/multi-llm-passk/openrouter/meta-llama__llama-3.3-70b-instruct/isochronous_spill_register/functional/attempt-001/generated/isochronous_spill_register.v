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

reg [WIDTH-1:0] buffer0;
reg [WIDTH-1:0] buffer1;
reg             buffer0_valid;
reg             buffer1_valid;

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        buffer0_valid <= 1'b0;
        buffer0       <= {WIDTH{1'b0}};
    end else if (src_valid_i &&!buffer0_valid) begin
        buffer0_valid <= 1'b1;
        buffer0       <= src_data_i;
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        buffer1_valid <= 1'b0;
        buffer1       <= {WIDTH{1'b0}};
        dst_valid_o   <= 1'b0;
        dst_data_o    <= {WIDTH{1'b0}};
    end else begin
        if (buffer0_valid &&!buffer1_valid && dst_ready_i) begin
            buffer1_valid <= 1'b1;
            buffer1       <= buffer0;
            buffer0_valid <= 1'b0;
            dst_valid_o   <= 1'b1;
            dst_data_o    <= buffer0;
        end else if (buffer1_valid && dst_ready_i) begin
            buffer1_valid <= 1'b0;
            dst_valid_o   <= 1'b0;
            dst_data_o    <= {WIDTH{1'b0}};
        end
    end
end

assign src_ready_o =!buffer0_valid;

endmodule
