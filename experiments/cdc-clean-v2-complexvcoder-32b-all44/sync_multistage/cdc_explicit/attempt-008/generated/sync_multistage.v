module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    // Internal signals for the pipeline stages
    logic [STAGES-1:0] pipeline;

    // Synchronization pipeline
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            pipeline <= {STAGES{ResetValue}};
        end else begin
            pipeline[0] <= serial_i;
            for (int i = 1; i < STAGES; i++) begin
                pipeline[i] <= pipeline[i-1];
            end
        end
    end

    // Output the last stage of the pipeline
    assign serial_o = pipeline[STAGES-1];

endmodule
