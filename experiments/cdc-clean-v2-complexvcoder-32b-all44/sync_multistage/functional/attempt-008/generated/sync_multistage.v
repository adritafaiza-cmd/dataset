module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    // Internal signal to connect the stages
    logic [STAGES-1:0] sync_stages;

    // First stage
    sync_stage #(.ResetValue(ResetValue)) sync_stage_inst_0 (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .d_i(serial_i),
        .q_o(sync_stages[0])
    );

    // Intermediate stages
    genvar i;
    generate
        for (i = 1; i < STAGES; i = i + 1) begin : gen_sync_stages
            sync_stage #(.ResetValue(ResetValue)) sync_stage_inst_i (
                .clk_i(clk_i),
                .rst_ni(rst_ni),
                .d_i(sync_stages[i-1]),
                .q_o(sync_stages[i])
            );
        end
    endgenerate

    // Final stage assignment
    assign serial_o = sync_stages[STAGES-1];

endmodule

module sync_stage #(
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic d_i,
    output logic q_o
);

    // Flip-flop to capture the input signal
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            q_o <= ResetValue;
        end else begin
            q_o <= d_i;
        end
    end

endmodule
