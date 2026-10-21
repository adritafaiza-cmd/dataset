module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    // Internal signal to handle polarity inversion if needed
    wire rst_active;
    assign rst_active = (RST_POL == 1'b1) ? async_rst_i : ~async_rst_i;

    // Stage 0: Immediate Assertion Capture
    // This stage ensures that if the reset is asserted, the output follows immediately.
    // It also handles the initial state where the pipeline might be in an undefined state.
    reg rst_stage0;
    always @(posedge clk or posedge rst_active) begin
        if (rst_active)
            rst_stage0 <= 1'b1;
        else
            rst_stage0 <= 1'b0;
    end

    // Pipeline stages for safe deassertion (release)
    // We use a chain of flip-flops to ensure the reset release is stable across multiple clock edges.
    genvar i;
    reg rst_pipe[CHAINS-1:0];

    // Instantiate the pipeline stages
    generate
        for (i = 0; i < CHAINS; i = i + 1) begin : rst_pipe_gen
            always @(posedge clk or posedge rst_active) begin
                if (rst_active)
                    rst_pipe[i] <= 1'b1;
                else
                    rst_pipe[i] <= rst_pipe[i-1];
            end
        end
    endgenerate

    // Final output logic
    // The output is asserted if the immediate stage is high OR if any stage in the pipeline is high.
    // This ensures that once the reset is released, it stays released until the pipeline confirms stability.
    assign sync_rst_o = rst_stage0 | rst_pipe[CHAINS-1];

endmodule<|im_end|>
