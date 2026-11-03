module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    ff_chain #(
        .CHAINS(CHAINS),
        .RST_POL(RST_POL)
    ) ff_chain_inst (
        .clk(clk),
        .async_rst_i(async_rst_i),
        .sync_rst_o(sync_rst_o)
    );

endmodule

module ff_chain #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    reg [CHAINS:0] rst_chain;

    always @(posedge clk) begin
        rst_chain[0] <= async_rst_i;
        for (integer i = 1; i <= CHAINS; i = i + 1) begin
            rst_chain[i] <= rst_chain[i - 1];
        end
    end

    assign sync_rst_o = RST_POL ? rst_chain[CHAINS] : ~rst_chain[CHAINS];

endmodule
