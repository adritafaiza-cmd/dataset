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
    // If RST_POL is 1, async_rst_i is active high. If 0, it is active low.
    // We convert the input to a standard active-high internal signal for logic simplicity.
    wire rst_active_high;
    assign rst_active_high = RST_POL ? async_rst_i : ~async_rst_i;

    // Stage 0: Capture the reset assertion immediately on the clock edge.
    // This ensures sync_rst_o follows assertion immediately.
    reg rst_stage0;
    always @(posedge clk) begin
        if (rst_active_high)
            rst_stage0 <= 1'b1;
        else
            rst_stage0 <= 1'b0;
    end

    // Stages 1 to CHAINS: Synchronize the release of the reset.
    // We use a chain of flip-flops to ensure the deassertion is stable
    // across multiple clock cycles before propagating to the output.
    // This prevents metastability issues associated with reset release.
    reg rst_chain;
    genvar i;
    generate
        for (i = 1; i <= CHAINS; i = i + 1) begin : rst_chain_stages
            reg rst_reg;
            always @(posedge clk) begin
                if (rst_active_high)
                    rst_reg <= 1'b1;
                else
                    rst_reg <= rst_chain;
            end
            assign rst_chain = rst_reg;
        end
    endgenerate

    // Output assignment
    // The output is the result of the synchronization chain.
    // If RST_POL is 1, rst_chain is active high, so we output it directly.
    // If RST_POL is 0, rst_chain is active low (inverted logic flow), so we invert it.
    assign sync_rst_o = RST_POL ? rst_chain : ~rst_chain;

endmodule
```<|im_end|>
