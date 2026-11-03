module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    // Instantiate the reset synchronizer chain
    reset_synchronizer_chain #(
        .CHAINS(CHAINS),
        .RST_POL(RST_POL)
    ) rst_sync_chain (
        .clk(clk),
        .async_rst_i(async_rst_i),
        .sync_rst_o(sync_rst_o)
    );

endmodule

module reset_synchronizer_chain #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    // Internal signal to hold the chain of flip-flops
    reg [CHAINS-1:0] rst_chain;

    always @(posedge clk or posedge async_rst_i) begin
        if (async_rst_i == RST_POL) begin
            // Assert the reset chain immediately
            rst_chain <= {CHAINS{1'b1}};
        end else begin
            // Shift the chain
            rst_chain <= {rst_chain[CHAINS-2:0], 1'b0};
        end
    end

    // Output the last stage of the chain
    assign sync_rst_o = rst_chain[CHAINS-1];

endmodule
