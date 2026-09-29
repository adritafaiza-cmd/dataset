module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

reg [CHAINS-1:0] sync_reg;

always @(posedge clk or posedge async_rst_i) begin
    if (async_rst_i) begin
        sync_reg <= {CHAINS{RST_POL}};
    end else begin
        sync_reg <= {sync_reg[CHAINS-2:0], ~RST_POL};
    end
end

assign sync_rst_o = sync_reg[CHAINS-1];

endmodule
