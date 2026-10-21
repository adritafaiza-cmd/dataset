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
    // Using a chain of flip-flops to synchronize the asynchronous input
    genvar i;
    generate
        for (i = 0; i < STAGES; i++) begin : stage_pipeline
            logic stage_data;
            
            if (i == 0) begin : first_stage
                // First stage captures the asynchronous input
                // Reset is handled globally, so this stage uses the global reset
                always_ff @(posedge clk_i or negedge rst_ni) begin
                    if (!rst_ni)
                        stage_data <= ResetValue;
                    else
                        stage_data <= serial_i;
                end
            end else begin : subsequent_stages
                // Subsequent stages capture the output of the previous stage
                // This ensures the data is fully synchronized to clk_i
                always_ff @(posedge clk_i or negedge rst_ni) begin
                    if (!rst_ni)
                        stage_data <= ResetValue;
                    else
                        stage_data <= stage_data; // Capture previous stage output
                end
            end
        end
    endgenerate

    // Assign the final synchronized output
    assign serial_o = stage_pipeline[STAGES - 1].stage_data;

endmodule<|im_end|>
