module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    reg [CHAINS-1:0] sync_reg;
    integer i;

    always @(posedge clk or posedge async_rst_i) begin
        if (async_rst_i) begin
            sync_reg <= {CHAINS{RST_POL}};
        end else begin
            sync_reg[0] <= ~RST_POL;
            for (i = 1; i < CHAINS; i = i + 1) begin
                sync_reg[i] <= sync_reg[i-1];
            end
        end
    end

    assign sync_rst_o = &sync_reg;

endmodule
