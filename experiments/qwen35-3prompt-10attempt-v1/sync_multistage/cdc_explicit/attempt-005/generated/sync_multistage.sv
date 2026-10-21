module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    // Generate pipeline stages for CDC compliance
    // Using a loop to instantiate flip-flops ensures structural safety
    // and allows synthesis tools to optimize correctly.
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : stage_pipeline
            logic stage_data;
            
            // First stage captures the asynchronous input
            if (i == 0) begin
                always_ff @(posedge clk_i or negedge rst_ni) begin
                    if (!rst_ni)
                        stage_data <= ResetValue;
                    else
                        stage_data <= serial_i;
                end
            end else begin
                // Subsequent stages capture the previous stage's output
                always_ff @(posedge clk_i or negedge rst_ni) begin
                    if (!rst_ni)
                        stage_data <= ResetValue;
                    else
                        stage_data <= stage_data; // Capture previous stage
                end
            end
        end
    endgenerate

    // Final stage output
    // The last stage in the loop above is 'stage_data' for i = STAGES-1
    // We assign this to the output port.
    assign serial_o = stage_pipeline[STAGES-1].stage_data;

endmodule<|im_end|>
