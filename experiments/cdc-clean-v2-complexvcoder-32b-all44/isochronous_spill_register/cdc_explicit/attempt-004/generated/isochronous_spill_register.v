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
    reg                valid_ff_0;
    reg                valid_ff_1;
    reg [WIDTH-1:0]    data_ff_0;
    reg [WIDTH-1:0]    data_ff_1;
    reg                src_ready;
    reg                dst_ready;

    // CDC registers for valid signal
    cdc_reg #(.WIDTH(1)) cdc_reg_inst_valid_0 (
        .clk    (src_clk_i),
        .rst_ni (src_rst_ni),
        .d      (src_valid_i),
        .q      (valid_ff_0)
    );

    cdc_reg #(.WIDTH(1)) cdc_reg_inst_valid_1 (
        .clk    (dst_clk_i),
        .rst_ni (dst_rst_ni),
        .d      (valid_ff_0),
        .q      (valid_ff_1)
    );

    // CDC registers for data signal
    cdc_reg #(.WIDTH(WIDTH)) cdc_reg_inst_data_0 (
        .clk    (src_clk_i),
        .rst_ni (src_rst_ni),
        .d      (src_data_i),
        .q      (data_ff_0)
    );

    cdc_reg #(.WIDTH(WIDTH)) cdc_reg_inst_data_1 (
        .clk    (dst_clk_i),
        .rst_ni (dst_rst_ni),
        .d      (data_ff_0),
        .q      (data_ff_1)
    );

    // Source-side logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ready <= 1'b0;
        end else begin
            src_ready <= dst_ready & !valid_ff_1;
        end
    end

    // Destination-side logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_ready <= 1'b0;
        end else begin
            dst_ready <= src_ready | valid_ff_1;
        end
    end

    // Assign outputs
    assign src_ready_o = src_ready;
    assign dst_valid_o = valid_ff_1;
    assign dst_data_o  = data_ff_1;

endmodule

module cdc_reg #(
    parameter WIDTH = 1
)(
    input              clk,
    input              rst_ni,
    input  [WIDTH-1:0] d,
    output [WIDTH-1:0] q
);

    reg [WIDTH-1:0] ff0;
    reg [WIDTH-1:0] ff1;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            ff0 <= {WIDTH{1'b0}};
            ff1 <= {WIDTH{1'b0}};
        end else begin
            ff0 <= d;
            ff1 <= ff0;
        end
    end

    assign q = ff1;

endmodule
