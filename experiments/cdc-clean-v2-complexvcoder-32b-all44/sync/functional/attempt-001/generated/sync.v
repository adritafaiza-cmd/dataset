module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    // Internal signal array to hold the synchronization stages
    logic [STAGES-1:0] sync_stages;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            // Reset all stages to ResetValue
            sync_stages <= {STAGES{ResetValue}};
        end else begin
            // Shift the serial_i through the stages
            sync_stages <= {sync_stages[STAGES-2:0], serial_i};
        end
    end

    // Assign the final stage to the output
    assign serial_o = sync_stages[STAGES-1];

endmodule
