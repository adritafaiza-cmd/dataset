module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    logic [STAGES-1:0] stages;

    // First stage
    ff_stage #(.ResetValue(ResetValue)) ff_stage_0 (
        .clk_i  (clk_i),
        .rst_ni (rst_ni),
        .d      (serial_i),
        .q      (stages[0])
    );

    // Intermediate stages
    generate
        genvar i;
        for (i = 1; i < STAGES; i = i + 1) begin : gen_ff_stages
            ff_stage #(.ResetValue(ResetValue)) ff_stage_i (
                .clk_i  (clk_i),
                .rst_ni (rst_ni),
                .d      (stages[i-1]),
                .q      (stages[i])
            );
        end
    endgenerate

    // Assign the output from the last stage
    assign serial_o = stages[STAGES-1];

endmodule

module ff_stage #(
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic d,
    output logic q
);

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            q <= ResetValue;
        end else begin
            q <= d;
        end
    end

endmodule
