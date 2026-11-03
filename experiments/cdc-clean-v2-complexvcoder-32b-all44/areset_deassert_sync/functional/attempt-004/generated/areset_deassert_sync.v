module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    // Internal signal to hold the reset chain
    reg [CHAINS-1:0] rst_chain;

    always @(posedge clk) begin
        // Set the first stage of the chain to the async reset input
        rst_chain[0] <= async_rst_i;

        // Shift the reset through the chain
        for (integer i = 1; i < CHAINS; i = i + 1) begin
            rst_chain[i] <= rst_chain[i-1];
        end
    end

    // The output reset follows the last stage of the chain
    assign sync_rst_o = rst_chain[CHAINS-1];

endmodule
