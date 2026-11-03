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
    ) sync_chain_inst (
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

    // Internal register chain
    reg [CHAINS-1:0] sync_chain_reg;

    always @(posedge clk or posedge async_rst_i) begin
        if (async_rst_i == RST_POL) begin
            sync_chain_reg <= {CHAINS{RST_POL}};
        end else begin
            sync_chain_reg <= {sync_chain_reg[CHAINS-2:0], ~RST_POL};
        end
    end

    // Assign the final synchronized reset output
    assign sync_rst_o = sync_chain_reg[CHAINS-1];

endmodule
