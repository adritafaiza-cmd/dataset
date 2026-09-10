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

    reg [WIDTH-1:0] data_reg1;
    reg [WIDTH-1:0] data_reg2;
    reg             valid_reg1;
    reg             valid_reg2;

    wire             src_ready_int;
    wire             dst_valid_int;

    assign src_ready_o = src_ready_int;
    assign dst_valid_o = dst_valid_int;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (~src_rst_ni) begin
            data_reg1 <= {WIDTH{1'b0}};
            valid_reg1 <= 1'b0;
        end else if (src_valid_i && src_ready_int) begin
            data_reg1 <= src_data_i;
            valid_reg1 <= 1'b1;
        end else if (~src_valid_i && src_ready_int) begin
            valid_reg1 <= 1'b0;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (~dst_rst_ni) begin
            data_reg2 <= {WIDTH{1'b0}};
            valid_reg2 <= 1'b0;
        end else if (valid_reg1 && dst_ready_i) begin
            data_reg2 <= data_reg1;
            valid_reg2 <= 1'b1;
        end else if (~valid_reg1 && dst_ready_i) begin
            valid_reg2 <= 1'b0;
        end
    end

    always @(posedge src_clk_i) begin
        src_ready_int <= (~valid_reg1 || (valid_reg1 && dst_ready_i));
    end

    always @(posedge dst_clk_i) begin
        dst_valid_int <= valid_reg2;
        dst_data_o <= data_reg2;
    end

endmodule
