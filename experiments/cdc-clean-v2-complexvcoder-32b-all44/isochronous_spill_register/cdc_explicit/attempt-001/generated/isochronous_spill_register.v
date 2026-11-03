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

    // Internal signals
    reg                src_valid_1;
    reg                src_valid_2;
    reg [WIDTH-1:0]    src_data_1;
    reg [WIDTH-1:0]    src_data_2;
    reg                dst_ready_1;
    reg                dst_ready_2;

    // Cross-domain flip-flops for src_valid_i
    cdc_flip_flop ff_src_valid_1 (
        .d        (src_valid_i),
        .clk      (src_clk_i),
        .rst_ni   (src_rst_ni),
        .q        (src_valid_1)
    );

    cdc_flip_flop ff_src_valid_2 (
        .d        (src_valid_1),
        .clk      (src_clk_i),
        .rst_ni   (src_rst_ni),
        .q        (src_valid_2)
    );

    // Cross-domain flip-flops for src_data_i
    cdc_flip_flop #(.WIDTH(WIDTH)) ff_src_data_1 (
        .d        (src_data_i),
        .clk      (src_clk_i),
        .rst_ni   (src_rst_ni),
        .q        (src_data_1)
    );

    cdc_flip_flop #(.WIDTH(WIDTH)) ff_src_data_2 (
        .d        (src_data_1),
        .clk      (src_clk_i),
        .rst_ni   (src_rst_ni),
        .q        (src_data_2)
    );

    // Cross-domain flip-flops for dst_ready_i
    cdc_flip_flop ff_dst_ready_1 (
        .d        (dst_ready_i),
        .clk      (dst_clk_i),
        .rst_ni   (dst_rst_ni),
        .q        (dst_ready_1)
    );

    cdc_flip_flop ff_dst_ready_2 (
        .d        (dst_ready_1),
        .clk      (dst_clk_i),
        .rst_ni   (dst_rst_ni),
        .q        (dst_ready_2)
    );

    // Output assignments
    assign dst_valid_o = src_valid_2;
    assign dst_data_o  = src_data_2;
    assign src_ready_o = dst_ready_2;

endmodule

module cdc_flip_flop #(
    parameter WIDTH = 1
)(
    input  [WIDTH-1:0] d,
    input              clk,
    input              rst_ni,
    output [WIDTH-1:0] q
);

    reg [WIDTH-1:0] q_reg;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            q_reg <= {WIDTH{1'b0}};
        end else begin
            q_reg <= d;
        end
    end

    assign q = q_reg;

endmodule
