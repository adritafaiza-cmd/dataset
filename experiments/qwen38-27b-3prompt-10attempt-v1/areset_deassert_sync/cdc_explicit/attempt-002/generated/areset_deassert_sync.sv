module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    localparam integer DEPTH = (CHAINS < 2) ? 2 : CHAINS;

    reg [DEPTH-1:0] sync_reg;
    reg             rst_active;

    // Synchronize the reset signal into the clock domain
    // For active-high reset: sync_reg tracks the reset state
    // For active-low reset: we invert the input first

    wire rst_sync_in = (RST_POL == 1'b1) ? async_rst_i : ~async_rst_i;

    // First stage of synchronizer
    always @(posedge clk or posedge rst_sync_in) begin
        if (rst_sync_in)
            sync_reg <= {DEPTH{1'b1}};
        else
            sync_reg <= {sync_reg[DEPTH-2:0], 1'b1};
    end

    // The reset is considered active if any stage is still 0
    // (i.e., the reset has not fully propagated through the chain)
    wire rst_released = &sync_reg;

    // sync_rst_o is active when reset is asserted OR not yet released
    // For active-high: sync_rst_o = 1 when reset active
    // For active-low: sync_rst_o = 0 when reset active
    assign sync_rst_o = (RST_POL == 1'b1) ? ~rst_released : rst_released;

endmodule
