module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    localparam ACTIVE = RST_POL;
    localparam INACTIVE = ~RST_POL;

    reg [CHAINS-1:0] sync_reg;

    // Synchronous reset: when async_rst_i is active, force sync_reg to active
    // When async_rst_i is inactive, shift register to inactive
    always @(posedge clk) begin
        if (async_rst_i == ACTIVE)
            sync_reg <= {CHAINS{ACTIVE}};
        else
            sync_reg <= {sync_reg[CHAINS-2:0], INACTIVE};
    end

    assign sync_rst_o = sync_reg[CHAINS-1];

endmodule
