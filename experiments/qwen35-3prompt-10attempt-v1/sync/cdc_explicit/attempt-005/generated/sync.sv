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
        for (i = 0; i < STAGES; i = i + 1) begin : stage_pipeline
            logic sync_stage;
            
            // First stage captures the asynchronous input on the target clock
            // Subsequent stages ensure setup/hold time safety and filter metastability
            if (i == 0) begin : first_stage
                always_ff @(posedge clk_i or negedge rst_ni) begin
                    if (!rst_ni)
                        sync_stage <= ResetValue;
                    else
                        sync_stage <= serial_i;
                end
            end else begin : subsequent_stages
                always_ff @(posedge clk_i or negedge rst_ni) begin
                    if (!rst_ni)
                        sync_stage <= ResetValue;
                    else
                        sync_stage <= sync_stage; // Hold previous value
                end
            end
        end
    endgenerate

    // Final output is the last stage of the pipeline
    assign serial_o = sync_stage;

endmodule<|im_end|>
