module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    // Internal clock for the destination domain (same as clk_i)
    // We use a single flip-flop chain to synchronize the asynchronous bit.
    // Since serial_i is a single bit, we do not need multi-bit handshaking.
    // The chain ensures that the data is stable in the destination clock domain
    // before being passed to the output.

    // Generate a chain of flip-flops to synchronize the asynchronous input.
    // Each stage captures the output of the previous stage on the rising edge of clk_i.
    // This creates a safe crossing for the single-bit data.
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : stage_gen
            logic sync_stage;
            
            // First stage captures the asynchronous input
            if (i == 0) begin
                always_ff @(posedge clk_i or negedge rst_ni) begin
                    if (!rst_ni)
                        sync_stage <= ResetValue;
                    else
                        sync_stage <= serial_i;
                end
            end else begin
                // Subsequent stages capture the previous stage's output
                always_ff @(posedge clk_i or negedge rst_ni) begin
                    if (!rst_ni)
                        sync_stage <= ResetValue;
                    else
                        sync_stage <= sync_stage[i-1];
                end
            end
        end
    endgenerate

    // The final stage output is the synchronized data
    assign serial_o = sync_stage[STAGES-1];

endmodule<|im_end|>
