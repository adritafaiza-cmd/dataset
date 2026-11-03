module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    reg [CHAINS-1:0] rst_sync_chain;

    always @(posedge clk or posedge async_rst_i) begin
        if (async_rst_i == RST_POL) begin
            rst_sync_chain <= {CHAINS{RST_POL}};
        end else begin
            rst_sync_chain <= {rst_sync_chain[CHAINS-2:0], 1'b0};
        end
    end

    assign sync_rst_o = rst_sync_chain[CHAINS-1];

endmodule
