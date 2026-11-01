module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    // Normalize reset polarity: work with active-high internally
    wire rst_active = (RST_POL == 1'b1) ? async_rst_i : ~async_rst_i;

    // Synchronizer chain for reset deassertion
    // The chain synchronizes the deassertion of the reset
    // When rst_active goes low (deassert), the chain will eventually go low
    // We need to detect when the chain has settled to 0 (deasserted)

    // Generate a chain of flip-flops
    // The last stage of the chain indicates that the reset has been safely deasserted
    // sync_rst_o should be active (high if RST_POL=1) when either:
    //   1. rst_active is high (reset asserted) - immediate
    //   2. The synchronizer chain has not yet fully deasserted

    // For active-high reset (RST_POL=1):
    //   sync_rst_o = rst_active | ~chain_last
    //   When rst_active=1, sync_rst_o=1 immediately
    //   When rst_active=0, sync_rst_o follows ~chain_last, which starts at 1 and goes to 0 after CHAINS cycles

    // For active-low reset (RST_POL=0):
    //   sync_rst_o should be active-low when reset is active
    //   sync_rst_o = ~rst_active & chain_last  ... wait, let me think again

    // Let me reconsider. The output sync_rst_o should have the same polarity as async_rst_i.
    // If RST_POL=1, sync_rst_o is active-high.
    // If RST_POL=0, sync_rst_o is active-low.

    // Internal: work with active-high reset signal
    // rst_active = 1 means reset is asserted

    // Synchronizer chain: synchronizes the deassertion of rst_active
    // chain[0] <= rst_active (or rather, we want to sync the transition)
    // Actually, for reset deassertion synchronization, we synchronize the reset signal itself.
    // When rst_active goes from 1 to 0, the chain will propagate the 0 over CHAINS cycles.
    // The last stage being 0 means the reset has been safely deasserted.

    // So: sync_rst_o (active-high) = rst_active | ~chain_last
    // When rst_active=1: sync_rst_o=1 (immediate assertion)
    // When rst_active=0: sync_rst_o = ~chain_last
    //   Initially after deassert, chain_last is still 1 (from previous state), so ~chain_last=0? No...
    //   Wait, if rst_active was 1, all chain stages were 1. When rst_active goes to 0:
    //   cycle 1: chain[0]=0, chain[1]=1, ..., chain_last=1 -> ~chain_last=0 -> sync_rst_o=0? That's wrong.

    // Let me reconsider. The standard approach:
    // The synchronizer chain is clocked and resets to the active state.
    // We want sync_rst_o to remain active until the chain has fully synchronized the deassertion.

    // Standard reset deassert synchronizer:
    // - Use a chain of flip-flops that are reset by the async reset
    // - The last flip-flop in the chain, when it deasserts, indicates safe deassertion
    // - sync_rst_o = async_rst_i | ~last_ff (for active-high)

    // When async_rst_i=1: all FFs are reset to 1, last_ff=1, ~last_ff=0, sync_rst_o=1|0=1
    // When async_rst_i=0: FFs start clocking in 0s
    //   After CHAINS cycles, last_ff=0, ~last_ff=1, sync_rst_o=0|1=1? That's wrong too.

    // I think I have the logic inverted. Let me think about what "safe deassert" means.
    // The reset is asserted (active). We want to release it safely.
    // The synchronizer ensures that the deassertion is synchronized to the clock.
    // sync_rst_o should be active (resetting) until the deassertion is safely synchronized.

    // So sync_rst_o should be:
    // - Active when async_rst_i is active (immediate)
    // - Remain active for a few cycles after async_rst_i deasserts, until the synchronizer confirms safe deassert

    // For active-high:
    // sync_rst_o = async_rst_i | ~sync_done
    // where sync_done indicates the synchronizer has confirmed deassertion

    // The synchronizer chain: each stage is a D flip-flop with async reset
    // When async_rst_i=1, all stages are 1 (reset)
    // When async_rst_i=0, stages clock in 0
    // After CHAINS cycles, all stages are 0
    // sync_done = ~last_stage (when last_stage=0, sync_done=1)
    // But wait, when async_rst_i=1, last_stage=1, sync_done=0, sync_rst_o=1|1=1. Good.
    // When async_rst_i=0, after CHAINS cycles, last_stage=0, sync_done=1, sync_rst_o=0|0=0. Good.
    // During transition: async_rst_i=0, last_stage still 1 for a few cycles, sync_done=0, sync_rst_o=0|1=1. Good.

    // So: sync_rst_o = async_rst_i | ~last_stage (for active-high)

    // For active-low (RST_POL=0):
    // async_rst_i is active-low. rst_active = ~async_rst_i
    // sync_rst_o should be active-low
    // sync_rst_o = ~async_rst_i & last_stage? Let me think...
    // When async_rst_i=0 (active), rst_active=1, all stages=1, last_stage=1
    // sync_rst_o should be 0 (active-low)
    // When async_rst_i=1 (inactive), rst_active=0, stages clock to 0, last_stage=0 after CHAINS
    // sync_rst_o should be 1 (inactive)
    // sync_rst_o = ~rst_active | last_stage? 
    //   When rst_active=1: ~1|1 = 0|1=1. Wrong, should be 0.
    // sync_rst_o = ~rst_active & ~last_stage?
    //   When rst_active=1: 0 & 0 = 0. Good.
    //   When rst_active=0, last_stage=1 (during transition): 1 & 0 = 0. Good (still active)
    //   When rst_active=0, last_stage=0 (after CHAINS): 1 & 1 = 1. Good (inactive)
    // So for active-low: sync_rst_o = ~rst_active & ~last_stage

    // Alternatively, we can unify:
    // For RST_POL=1: sync_rst_o = rst_active | ~last_stage
    // For RST_POL=0: sync_rst_o = ~rst_active & ~last_stage

    // Let's implement with a generate block for the chain

    reg [CHAINS-1:0] sync_chain;

    integer i;
    always @(posedge clk or posedge rst_active) begin
        if (rst_active)
            sync_chain <= {CHAINS{1'b1}};
        else
            for (i = 0; i < CHAINS; i = i + 1)
                sync_chain[i] <= (i == 0) ? 1'b0 : sync_chain[i-1];
    end

    wire last_stage = sync_chain[CHAINS-1];

    assign sync_rst_o = (RST_POL == 1'b1) ? (rst_active | ~last_stage) : (~rst_active & ~last_stage);

endmodule
