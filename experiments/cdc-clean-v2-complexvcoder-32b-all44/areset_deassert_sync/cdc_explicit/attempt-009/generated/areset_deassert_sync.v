module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    // Internal synchronization chain
    reg [CHAINS-1:0] rst_sync_chain;

    always @(posedge clk or posedge async_rst_i) begin
        if (async_rst_i == RST_POL) begin
            // Assert sync_rst_o immediately when async_rst_i is active
            rst_sync_chain <= {CHAINS{1'b1}};
        end else begin
            // Shift the chain to deassert sync_rst_o
            rst_sync_chain <= {rst_sync_chain[CHAINS-2:0], 1'b0};
        end
    end

    // Output the synchronized reset
    assign sync_rst_o = rst_sync_chain[CHAINS-1];

endmodule
