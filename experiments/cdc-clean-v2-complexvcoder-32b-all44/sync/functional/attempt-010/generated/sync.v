module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    // Internal pipeline signal
    logic [STAGES-1:0] sync_pipeline;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            // Reset the pipeline to ResetValue
            sync_pipeline <= {STAGES{ResetValue}};
        end else begin
            // Shift the pipeline
            sync_pipeline <= {sync_pipeline[STAGES-2:0], serial_i};
        end
    end

    // Output the last stage of the pipeline
    assign serial_o = sync_pipeline[STAGES-1];

endmodule
