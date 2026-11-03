module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    // Internal signal to hold the synchronized reset chain
    reg [CHAINS-1:0] rst_chain;

    // Synchronize the asynchronous reset to the synchronous domain
    always @(posedge clk or posedge async_rst_i) begin
        if (async_rst_i == RST_POL) begin
            rst_chain <= {CHAINS{1'b1}};
        end else begin
            rst_chain <= {rst_chain[CHAINS-2:0], 1'b0};
        end
    end

    // Assign the final synchronized reset output
    assign sync_rst_o = rst_chain[CHAINS-1];

endmodule
