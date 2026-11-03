module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

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

    reg [CHAINS-1:0] sync_chain_reg;

    always @(posedge clk) begin
        sync_chain_reg[0] <= async_rst_i;
        for (int i = 1; i < CHAINS; i = i + 1) begin
            sync_chain_reg[i] <= sync_chain_reg[i-1];
        end
    end

    assign sync_rst_o = RST_POL ? sync_chain_reg[CHAINS-1] : ~sync_chain_reg[CHAINS-1];

endmodule
