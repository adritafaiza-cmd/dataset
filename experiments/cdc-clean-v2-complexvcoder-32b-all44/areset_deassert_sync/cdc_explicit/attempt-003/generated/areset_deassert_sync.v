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
        .CHAINS(CHAINS),
        .RST_POL(RST_POL)
    ) rst_sync_chain (
        .clk(clk),
        .async_rst_i(async_rst_i),
        .sync_rst_o(sync_rst_o)
    );

endmodule

module sync_chain #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    reg [CHAINS-1:0] sync_chain_stages;

    always @(posedge clk or posedge async_rst_i) begin
        if (RST_POL ? async_rst_i : !async_rst_i) begin
            sync_chain_stages <= {CHAINS{1'b1}};
        end else begin
            sync_chain_stages <= {sync_chain_stages[CHAINS-2:0], 1'b0};
        end
    end

    assign sync_rst_o = sync_chain_stages[CHAINS-1];

endmodule
