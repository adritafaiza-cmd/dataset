```verilog
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
    assign rst_active = RST_POL ? async_rst_i : ~async_rst_i;

    // Pipeline stage for the release of the reset
    // We use a chain of flip-flops to ensure the deassertion is stable
    // before propagating to the output.
    reg [CHAINS-1:0] rst_pipe;

    // First stage: Capture the reset state on the clock edge
    // If rst_active is high (asserted), the pipeline holds '1'.
    // If rst_active goes low (deasserted), the pipeline starts shifting '0's.
    always @(posedge clk) begin
        if (rst_active) begin
            rst_pipe[0] <= 1'b1;
        end else begin
            // Shift register behavior: shift in 0 if not asserted
            rst_pipe[0] <= 1'b0;
            for (integer i = 1; i < CHAINS; i = i + 1) begin
                rst_pipe[i] <= rst_pipe[i-1];
            end
        end
    end

    // Output is the last stage of the pipeline
    // This ensures the reset is only released after CHAINS clock cycles
    // of stable deassertion.
    assign sync_rst_o = rst_pipe[CHAINS-1];

endmodule
```<|im_end|>
