module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

reg [CHAINS-1:0] rst_chain;
reg [CHAINS-1:0] rst_chain_d;

always @(posedge clk or negedge clk) begin
    if (!clk) begin
        rst_chain_d <= {CHAINS{1'b0}};
    end else begin
        if (async_rst_i == RST_POL) begin
            rst_chain_d <= {CHAINS{1'b1}};
        end else begin
            rst_chain_d <= {rst_chain[CHAINS-2:0], 1'b0};
        end
    end
end

always @(posedge clk) begin
    rst_chain <= rst_chain_d;
end

assign sync_rst_o = (rst_chain[CHAINS-1] == 1'b1) ? 1'b1 : 1'b0;

endmodule
