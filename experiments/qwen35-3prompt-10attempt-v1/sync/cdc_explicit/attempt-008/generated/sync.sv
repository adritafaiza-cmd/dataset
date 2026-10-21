module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    // Generate a chain of flip-flops to synchronize the asynchronous input
    // to the domain of clk_i.
    // STAGES defines the depth of the synchronizer.
    // A depth of 2 or more is standard for single-bit asynchronous inputs
    // to filter out metastability.
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : stage_ff
            logic sync_stage;
            
            // First stage captures the asynchronous input on the synchronous clock.
            // Subsequent stages capture the output of the previous stage.
            always_ff @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni)
                    sync_stage <= ResetValue;
                else
                    sync_stage <= (i == 0) ? serial_i : sync_stage[i-1];
            end
        end
    endgenerate

    // The final stage output is the synchronized data.
    assign serial_o = sync_stage[STAGES - 1];

endmodule<|im_end|>
