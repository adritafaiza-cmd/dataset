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
    reg                ff1_din;
    wire               ff1_dout;
    reg                ff2_din;
    wire               ff2_dout;
    reg  [WIDTH-1:0]   ff1_data_din;
    wire [WIDTH-1:0]   ff1_data_dout;
    reg  [WIDTH-1:0]   ff2_data_din;
    wire [WIDTH-1:0]   ff2_data_dout;
    wire               src_ready;
    wire               dst_ready;

    // Cross-clock flip-flops
    cross_clock_ff #(WIDTH) ff1 (
        .clk_i  (src_clk_i),
        .rst_ni (src_rst_ni),
        .din    (ff1_din),
        .dout   (ff1_dout),
        .clk_o  (dst_clk_i)
    );

    cross_clock_ff #(WIDTH) ff2 (
        .clk_i  (src_clk_i),
        .rst_ni (src_rst_ni),
        .din    (ff2_din),
        .dout   (ff2_dout),
        .clk_o  (dst_clk_i)
    );

    cross_clock_ff #(.WIDTH(1)) ff1_valid (
        .clk_i  (src_clk_i),
        .rst_ni (src_rst_ni),
        .din    (src_valid_i),
        .dout   (ff1_dout),
        .clk_o  (dst_clk_i)
    );

    cross_clock_ff #(.WIDTH(1)) ff2_valid (
        .clk_i  (src_clk_i),
        .rst_ni (src_rst_ni),
        .din    (ff1_dout),
        .dout   (ff2_dout),
        .clk_o  (dst_clk_i)
    );

    cross_clock_ff #(WIDTH) ff1_data (
        .clk_i  (src_clk_i),
        .rst_ni (src_rst_ni),
        .din    (src_data_i),
        .dout   (ff1_data_dout),
        .clk_o  (dst_clk_i)
    );

    cross_clock_ff #(WIDTH) ff2_data (
        .clk_i  (src_clk_i),
        .rst_ni (src_rst_ni),
        .din    (ff1_data_dout),
        .dout   (ff2_data_dout),
        .clk_o  (dst_clk_i)
    );

    // Ready signals
    assign src_ready_o = ~ff1_dout;
    assign dst_valid_o = ff2_dout;
    assign dst_data_o  = ff2_data_dout;

endmodule

module cross_clock_ff #(
    parameter WIDTH = 1
)(
    input              clk_i,
    input              rst_ni,
    input  [WIDTH-1:0] din,
    output [WIDTH-1:0] dout,
    input              clk_o
);

    reg  [WIDTH-1:0] reg_i;
    reg  [WIDTH-1:0] reg_o;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            reg_i <= {WIDTH{1'b0}};
        end else begin
            reg_i <= din;
        end
    end

    always @(posedge clk_o or negedge rst_ni) begin
        if (!rst_ni) begin
            reg_o <= {WIDTH{1'b0}};
        end else begin
            reg_o <= reg_i;
        end
    end

    assign dout = reg_o;

endmodule
