module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    wire sync_rst_i;
    sync_chain #(
        .CHAINS(CHAINS),
        .RST_POL(RST_POL)
    ) rst_sync_chain (
        .clk(clk),
        .async_rst_i(async_rst_i),
        .sync_rst_o(sync_rst_i)
    );

    reg [CHAINS-1:0] rst_chain;

    always @(posedge clk) begin
        if (sync_rst_i) begin
            rst_chain <= {CHAINS{1'b1}};
        end else begin
            rst_chain <= {rst_chain[CHAINS-2:0], 1'b0};
        end
    end

    assign sync_rst_o = rst_chain[CHAINS-1];

endmodule

module sync_chain #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    reg [CHAINS-1:0] rst_chain;

    always @(posedge clk or posedge async_rst_i) begin
        if (RST_POL ? async_rst_i : !async_rst_i) begin
            rst_chain <= {CHAINS{1'b1}};
        end else begin
            rst_chain <= {rst_chain[CHAINS-2:0], rst_chain[CHAINS-1]};
        end
    end

    assign sync_rst_o = rst_chain[CHAINS-1];

endmodule
