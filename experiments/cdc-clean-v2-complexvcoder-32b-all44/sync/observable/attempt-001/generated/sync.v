module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    // Internal signals to connect the flip-flop stages
    logic [STAGES-2:0] stages;

    // Instantiate the first stage of the synchronizer
    ff_stage #(.ResetValue(ResetValue)) ff_stage_0 (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .d_i(serial_i),
        .q_o(stages[0])
    );

    // Generate the remaining stages of the synchronizer
    genvar i;
    generate
        for (i = 1; i < STAGES-1; i = i + 1) begin : gen_ff_stages
            ff_stage #(.ResetValue(ResetValue)) ff_stage_i (
                .clk_i(clk_i),
                .rst_ni(rst_ni),
                .d_i(stages[i-1]),
                .q_o(stages[i])
            );
        end
    endgenerate

    // Instantiate the last stage of the synchronizer
    ff_stage #(.ResetValue(ResetValue)) ff_stage_last (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .d_i(stages[STAGES-2]),
        .q_o(serial_o)
    );

endmodule

module ff_stage #(
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic d_i,
    output logic q_o
);

    // Flip-flop with active-low reset
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            q_o <= ResetValue;
        end else begin
            q_o <= d_i;
        end
    end

endmodule
