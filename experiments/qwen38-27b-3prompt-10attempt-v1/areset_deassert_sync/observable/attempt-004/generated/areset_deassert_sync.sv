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

    // Synchronous reset for the synchronizer chain
    // When async_rst_i is in the active state, we want sync_reg to be in the active state
    // When async_rst_i is in the inactive state, we want sync_reg to be in the inactive state
    // We use a synchronous reset that drives the chain to the active state when async_rst_i is active
    // and lets it shift to the inactive state when async_rst_i is inactive

    // The idea: 
    // - When async_rst_i == ACTIVE, we want sync_rst_o to be ACTIVE (reset asserted)
    // - When async_rst_i == INACTIVE, we want sync_rst_o to transition to INACTIVE (reset deasserted) after CHAINS cycles
    //
    // We can implement this by:
    // - Using a shift register where the input is async_rst_i
    // - But we need to handle the polarity correctly
    //
    // Let's think of it differently:
    // We want sync_rst_o to be ACTIVE when async_rst_i is ACTIVE (immediately or after 1 cycle)
    // and to become INACTIVE after CHAINS cycles of async_rst_i being INACTIVE
    //
    // A common approach:
    // - The synchronizer chain tracks async_rst_i
    // - sync_reg[0] is the first flip-flop, sync_reg[CHAINS-1] is the last
    // - We want sync_rst_o = sync_reg[CHAINS-1]
    // - But we need to ensure that when async_rst_i is ACTIVE, the output is ACTIVE promptly
    //
    // Actually, let's use a simpler approach:
    // - We want the output to be ACTIVE when async_rst_i is ACTIVE
    // - We want the output to become INACTIVE after CHAINS cycles of async_rst_i being INACTIVE
    //
    // This is equivalent to: sync_rst_o = async_rst_i synchronized to clk, with the understanding that
    // when async_rst_i goes from ACTIVE to INACTIVE, it takes CHAINS cycles for the output to follow
    //
    // But we also want the output to go ACTIVE promptly when async_rst_i goes ACTIVE
    //
    // One way: use a shift register where the MSB is the output, and the input is async_rst_i
    // But this would delay the ACTIVE assertion by CHAINS cycles too
    //
    // Better approach: 
    // - When async_rst_i is ACTIVE, force sync_rst_o to ACTIVE
    // - When async_rst_i is INACTIVE, use the synchronizer chain to deassert
    //
    // Let's implement it as:
    // sync_rst_o = async_rst_i | sync_reg[CHAINS-1]  (if ACTIVE is 1)
    // or
    // sync_rst_o = async_rst_i & sync_reg[CHAINS-1]  (if ACTIVE is 0)
    //
    // Wait, let me reconsider. The standard approach for reset deassertion synchronizer:
    // - The reset is asserted asynchronously (or synchronously) but deasserted synchronously
    // - We want: when async_rst_i is active, sync_rst_o is active
    // - When async_rst_i is inactive, sync_rst_o becomes inactive after CHAINS cycles
    //
    // Implementation:
    // - Use a shift register that shifts in async_rst_i
    // - The output is the last stage
    // - But we need to handle the case where async_rst_i is active: we want the output to be active immediately
    //
    // Actually, the simplest correct approach:
    // - sync_reg is a shift register with async_rst_i as input
    // - sync_rst_o = sync_reg[CHAINS-1]
    // - This means when async_rst_i goes ACTIVE, it takes CHAINS cycles for sync_rst_o to go ACTIVE
    // - This is NOT what we want for "assert promptly"
    //
    // So we need: sync_rst_o = async_rst_i | sync_reg[CHAINS-1] (for active-high)
    // This way, when async_rst_i is ACTIVE, sync_rst_o is ACTIVE immediately
    // When async_rst_i is INACTIVE, sync_rst_o follows sync_reg[CHAINS-1] which will become INACTIVE after CHAINS cycles
    //
    // For active-low: sync_rst_o = async_rst_i & sync_reg[CHAINS-1]
    // When async_rst_i is ACTIVE (0), sync_rst_o is 0 (active) immediately
    // When async_rst_i is INACTIVE (1), sync_rst_o follows sync_reg[CHAINS-1] which will become 1 (inactive) after CHAINS cycles

    always @(posedge clk) begin
        sync_reg[0] <= async_rst_i;
        for (integer i = 1; i < CHAINS; i = i + 1)
            sync_reg[i] <= sync_reg[i-1];
    end

    assign sync_rst_o = (RST_POL == 1'b1) ? (async_rst_i | sync_reg[CHAINS-1]) 
                                           : (async_rst_i & sync_reg[CHAINS-1]);

endmodule
