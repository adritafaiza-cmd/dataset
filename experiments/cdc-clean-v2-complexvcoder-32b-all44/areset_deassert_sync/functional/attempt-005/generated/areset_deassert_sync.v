module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    reg [CHAINS-1:0] rst_sync_chain;

    always @(posedge clk) begin
        // Synchronize the async reset into the clock domain
        rst_sync_chain <= {rst_sync_chain[CHAINS-2:0], async_rst_i};
    end

    // Determine the output reset based on the synchronized chain
    assign sync_rst_o = (RST_POL == 1'b1) ? rst_sync_chain[CHAINS-1] : ~rst_sync_chain[CHAINS-1];

endmodule
