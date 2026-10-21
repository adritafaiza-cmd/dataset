module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    // Internal signal to handle polarity inversion if needed
    wire rst_active = (RST_POL == 1'b1) ? async_rst_i : ~async_rst_i;

    // Stage 0: Capture the reset assertion immediately on the first clock edge.
    // This ensures sync_rst_o follows async_rst_i immediately upon arrival.
    reg rst_stage0;
    always @(posedge clk or posedge rst_active) begin
        if (rst_active)
            rst_stage0 <= 1'b1;
        else
            rst_stage0 <= 1'b0;
    end

    // Pipeline stages for safe deassertion (release)
    // We use a chain of flip-flops to ensure the reset release is stable
    // across multiple clock cycles before propagating to the output.
    genvar i;
    reg rst_pipe[0:CHAINS-1];

    // Instantiate the pipeline stages
    generate
        for (i = 0; i < CHAINS; i = i + 1) begin : rst_pipeline
            always @(posedge clk or posedge rst_stage0) begin
                if (rst_stage0)
                    rst_pipe[i] <= 1'b1;
                else
                    rst_pipe[i] <= rst_pipe[i-1 : 0];
            end
        end
    endgenerate

    // Final stage output
    // The output is driven by the last stage of the pipeline.
    // It will only deassert after CHAINS clock cycles of stable deassertion.
    assign sync_rst_o = rst_pipe[CHAINS-1];

endmodule<|im_end|>
