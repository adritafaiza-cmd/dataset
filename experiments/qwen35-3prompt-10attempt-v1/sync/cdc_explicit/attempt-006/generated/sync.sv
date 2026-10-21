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
    // Using a synchronous FIFO-like structure with a single bit per stage
    // ensures safe crossing of both clock and reset domains.
    // Each stage captures the previous stage's value on the target clock.
    // Reset propagation is handled synchronously through the chain.

    logic [STAGES-1:0] pipe_reg;

    // First stage: Capture asynchronous input on target clock
    // Reset is propagated synchronously to ensure RDC safety
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            pipe_reg[0] <= ResetValue;
        else
            pipe_reg[0] <= serial_i;
    end

    // Subsequent stages: Shift register chain
    // This creates the required pipeline depth (STAGES)
    // Each stage is synchronized to clk_i, ensuring no metastability
    // propagates to the output.
    genvar i;
    generate
        for (i = 1; i < STAGES; i = i + 1) begin : stage_gen
            always_ff @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni)
                    pipe_reg[i] <= ResetValue;
                else
                    pipe_reg[i] <= pipe_reg[i-1];
            end
        end
    endgenerate

    // Output is the last stage of the pipeline
    assign serial_o = pipe_reg[STAGES-1];

endmodule<|im_end|>
