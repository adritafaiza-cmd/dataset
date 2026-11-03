module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    // Internal pipeline stages
    logic [STAGES-1:0] sync_pipeline;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            // Reset all pipeline stages to ResetValue
            sync_pipeline <= {STAGES{ResetValue}};
        end else begin
            // Shift the pipeline stages
            sync_pipeline <= {sync_pipeline[STAGES-2:0], serial_i};
        end
    end

    // Assign the last stage of the pipeline to the output
    assign serial_o = sync_pipeline[STAGES-1];

endmodule
