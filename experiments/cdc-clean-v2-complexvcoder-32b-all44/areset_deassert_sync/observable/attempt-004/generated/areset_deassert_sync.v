module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    // Instantiate the sync_chain module
    sync_chain #(
        .CHAINS(CHAINS)
    ) sync_chain_inst (
        .clk(clk),
        .async_in(async_rst_i),
        .sync_out(sync_rst_o)
    );

endmodule

module sync_chain #(
    parameter CHAINS = 2
)(
    input  clk,
    input  async_in,
    output sync_out
);

    reg [CHAINS-1:0] sync_chain;

    always @(posedge clk) begin
        sync_chain[0] <= async_in;
        sync_chain[CHAINS-1:1] <= sync_chain[CHAINS-2:0];
    end

    assign sync_out = sync_chain[CHAINS-1];

endmodule
