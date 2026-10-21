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
            logic sync_stage;
            
            // First stage captures the asynchronous input on the destination clock
            // Subsequent stages ensure metastability resolution and data coherence
            always_ff @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni)
                    sync_stage <= ResetValue;
                else if (i == 0)
                    sync_stage <= serial_i;
                else
                    sync_stage <= sync_stage;
            end
            
            // Assign output of the last stage to the module output
            if (i == STAGES - 1)
                serial_o <= sync_stage;
        end
    endgenerate

endmodule<|im_end|>
