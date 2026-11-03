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
        .async_in(async_rst_i),
        .sync_out(sync_rst_o)
    );

endmodule

module sync_chain #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_in,
    output sync_out
);

    reg [CHAINS-1:0] sync_chain;

    always @(posedge clk or posedge async_in) begin
        if (RST_POL == 1'b1) begin
            if (async_in) begin
                sync_chain <= {CHAINS{1'b1}};
            end else begin
                sync_chain <= {sync_chain[CHAINS-2:0], 1'b0};
            end
        end else begin
            if (!async_in) begin
                sync_chain <= {CHAINS{1'b0}};
            end else begin
                sync_chain <= {sync_chain[CHAINS-2:0], 1'b1};
            end
        end
    end

    assign sync_out = sync_chain[CHAINS-1];

endmodule
