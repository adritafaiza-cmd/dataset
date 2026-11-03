module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    // Instantiate the reset synchronizer submodule
    reset_synchronizer #(
        .CHAINS(CHAINS),
        .RST_POL(RST_POL)
    ) rst_sync (
        .clk(clk),
        .async_rst_i(async_rst_i),
        .sync_rst_o(sync_rst_o)
    );

endmodule

module reset_synchronizer #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    reg [CHAINS-1:0] rst_reg;

    always @(posedge clk) begin
        if (RST_POL) begin
            // Active-high reset
            rst_reg <= {rst_reg[CHAINS-2:0], async_rst_i};
        end else begin
            // Active-low reset
            rst_reg <= {rst_reg[CHAINS-2:0], ~async_rst_i};
        end
    end

    assign sync_rst_o = RST_POL ? rst_reg[CHAINS-1] : ~rst_reg[CHAINS-1];

endmodule
