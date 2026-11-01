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

    // Synchronize the incoming async reset into the clk domain
    always @(posedge clk) begin
        sync_reg[0] <= async_rst_i;
        for (integer i = 1; i < CHAINS; i = i + 1)
            sync_reg[i] <= sync_reg[i-1];
    end

    // Combine: assert immediately if async_rst_i is active,
    // otherwise use the synchronized (deasserted) value
    wire sync_active = sync_reg[CHAINS-1];

    // If async_rst_i is active, output active reset immediately
    // If async_rst_i is inactive, output based on synchronized chain
    // This ensures prompt assertion and clean deassertion
    assign sync_rst_o = async_rst_i ? ACTIVE : (sync_active ? ACTIVE : INACTIVE);

endmodule
