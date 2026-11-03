module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

reg [CHAINS:0] sync_chain;

always @(posedge clk) begin
    sync_chain[0] <= async_rst_i ^ RST_POL;
    for (int i = 1; i <= CHAINS; i = i + 1) begin
        sync_chain[i] <= sync_chain[i-1];
    end
end

assign sync_rst_o = sync_chain[CHAINS];

endmodule
