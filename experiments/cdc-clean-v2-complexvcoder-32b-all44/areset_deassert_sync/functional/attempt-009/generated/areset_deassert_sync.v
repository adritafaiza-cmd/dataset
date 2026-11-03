module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    // Internal signal to create the synchronizer chain
    reg [CHAINS-1:0] rst_sync_chain;

    always @(posedge clk) begin
        // Synchronize the async reset into the clock domain
        if (RST_POL) begin
            rst_sync_chain <= {CHAINS{async_rst_i}} & {CHAINS{~rst_sync_chain[CHAINS-1]}};
        end else begin
            rst_sync_chain <= {CHAINS{async_rst_i}} | {CHAINS{rst_sync_chain[CHAINS-1]}};
        end
    end

    // Output the synchronized reset
    assign sync_rst_o = rst_sync_chain[CHAINS-1];

endmodule
