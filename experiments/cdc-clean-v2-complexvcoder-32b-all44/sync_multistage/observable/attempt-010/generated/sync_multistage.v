module sync_multistage #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    // Internal signal to connect the stages
    logic [STAGES-1:0] sync_chain;

    // First stage directly connects to the asynchronous input
    sync_stage #(
        .ResetValue(ResetValue)
    ) sync_stage_inst_0 (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .serial_i(serial_i),
        .serial_o(sync_chain[0])
    );

    // Generate the remaining stages
    genvar i;
    generate
        for (i = 1; i < STAGES; i = i + 1) begin : gen_sync_stages
            sync_stage #(
                .ResetValue(ResetValue)
            ) sync_stage_inst_i (
                .clk_i(clk_i),
                .rst_ni(rst_ni),
                .serial_i(sync_chain[i-1]),
                .serial_o(sync_chain[i])
            );
        end
    endgenerate

    // Assign the final stage output to the module output
    assign serial_o = sync_chain[STAGES-1];

endmodule

module sync_stage #(
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    // Internal register for the synchronization stage
    logic sync_reg;

    // D flip-flop with active-low reset
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg <= ResetValue;
        end else begin
            sync_reg <= serial_i;
        end
    end

    // Output the synchronized value
    assign serial_o = sync_reg;

endmodule
