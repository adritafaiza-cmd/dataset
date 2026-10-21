module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    // Internal signal to handle polarity inversion if needed
    wire rst_asserted;
    assign rst_asserted = RST_POL ? async_rst_i : ~async_rst_i;

    // Stage 0: Immediate assertion capture
    // This stage ensures that if the reset is asserted, the output is asserted immediately.
    // It also handles the initial state where the domain might be in reset.
    reg rst_stage_0;
    always @(posedge clk or posedge rst_asserted) begin
        if (rst_asserted)
            rst_stage_0 <= 1'b1;
        else
            rst_stage_0 <= 1'b0;
    end

    // Pipeline stages for safe deassertion (release)
    // We use a chain of flip-flops to ensure the reset release is stable across multiple clock cycles.
    genvar i;
    reg rst_pipeline[0:CHAINS];

    // Instantiate the pipeline stages
    generate
        for (i = 0; i < CHAINS; i = i + 1) begin : rst_pipeline_stage
            always @(posedge clk or posedge rst_stage_0) begin
                if (rst_stage_0)
                    rst_pipeline[i] <= 1'b1;
                else
                    rst_pipeline[i] <= rst_pipeline[i-1 : 0];
            end
        end
    endgenerate

    // Final output logic
    // The output is asserted if any stage in the pipeline (including stage 0) is asserted.
    // This ensures that once the reset is released, it takes CHAINS+1 cycles to become inactive,
    // providing a safe window for the downstream logic to stabilize.
    assign sync_rst_o = rst_stage_0 | rst_pipeline[0];

endmodule<|im_end|>
