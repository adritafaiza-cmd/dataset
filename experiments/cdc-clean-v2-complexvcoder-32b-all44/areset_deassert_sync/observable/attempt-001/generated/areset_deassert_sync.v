module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    wire internal_sync_rst;

    sync_chain #(
        .CHAINS(CHAINS)
    ) sync_chain_inst (
        .clk(clk),
        .async_in(async_rst_i),
        .sync_out(internal_sync_rst)
    );

    // Apply the reset polarity
    assign sync_rst_o = (RST_POL == 1'b1) ? internal_sync_rst : ~internal_sync_rst;

endmodule

module sync_chain #(
    parameter CHAINS = 2
)(
    input  clk,
    input  async_in,
    output sync_out
);

    reg [CHAINS-1:0] sync_chain_reg;

    always @(posedge clk) begin
        sync_chain_reg[0] <= async_in;
        for (integer i = 1; i < CHAINS; i = i + 1) begin
            sync_chain_reg[i] <= sync_chain_reg[i-1];
        end
    end

    assign sync_out = sync_chain_reg[CHAINS-1];

endmodule
