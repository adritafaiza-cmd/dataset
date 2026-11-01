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

    always @(posedge clk) begin
        sync_reg <= {sync_reg[CHAINS-2:0], async_rst_i};
    end

    wire synced_rst = sync_reg[CHAINS-1];

    assign sync_rst_o = (synced_rst == ACTIVE) ? ACTIVE : INACTIVE;

endmodule
