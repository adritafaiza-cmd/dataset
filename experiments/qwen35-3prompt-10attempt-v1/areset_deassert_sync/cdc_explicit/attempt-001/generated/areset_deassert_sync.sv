module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    // Internal signal to handle polarity inversion if needed
    // If RST_POL is 1, async_rst_i is active high.
    // If RST_POL is 0, async_rst_i is active low, so we invert it for logic.
    wire rst_active;
    assign rst_active = RST_POL ? async_rst_i : ~async_rst_i;

    // Synchronizer chain for the release of the reset.
    // We need to detect the transition from asserted to deasserted.
    // Since the reset must follow assertion immediately, we pass the input directly
    // to the first stage of the synchronizer chain for the release detection.
    // The chain ensures that the deassertion is stable before propagating to the output.

    // Stage 0: Initial flip-flop (captures the first edge of deassertion)
    // We use a register that is cleared by the reset signal itself.
    // However, to ensure the reset propagates immediately upon assertion,
    // we drive the output directly from the reset input when asserted.
    
    // Architecture Strategy:
    // 1. When async_rst_i is asserted, sync_rst_o is asserted immediately (combinational).
    // 2. When async_rst_i is deasserted, we need to wait for CHAINS clock cycles
    //    to confirm the deassertion before releasing sync_rst_o.
    // 3. We use a chain of flip-flops to synchronize the "release" event.
    
    // Let's create a chain of registers that count down or simply delay the release.
    // A common robust method for reset release synchronization is a chain of flip-flops
    // that are cleared by the reset and then released only after the reset has been
    // deasserted for N clock cycles.
    
    // We will use a counter-like approach or a shift register approach.
    // Given the requirement "sync_rst_o may release only after clk has observed a safe deassert",
    // a chain of flip-flops where the last stage drives the output is sufficient.
    // The chain is initialized to 0 (inactive). When reset is active, all stages are 0.
    // When reset deasserts, the first stage captures the '1' (if we invert logic) or we track the state.
    
    // Simpler and more standard approach for Reset Release:
    // Use a chain of flip-flops that are cleared by the reset.
    // Once the reset is deasserted, the first flip-flop captures the fact that reset is gone.
    // Then we shift this "release" signal through the chain.
    // The output is released only when the last flip-flop in the chain indicates the release is stable.
    
    // However, the requirement says: "sync_rst_o must follow assertion of async_rst_i immediately."
    // This implies a direct path for assertion.
    // For release, we need a delay.
    
    // Implementation Plan:
    // 1. Direct path for assertion: sync_rst_o <= rst_active; (But this might conflict with the chain logic if not careful).
    //    Actually, if we use a chain that is cleared by reset, the output of the chain will be 0 during reset.
    //    So we can OR the direct reset signal with the chain output? No, that would keep it high during reset.
    //    We want: High during reset, Low after release.
    //    So: sync_rst_o = rst_active OR (chain_output_is_still_holding_reset_state).
    //    This is tricky because the chain needs to transition from "Reset Active" state to "Reset Released" state.
    
    // Revised Plan:
    // Use a chain of flip-flops to synchronize the *deassertion* event.
    // Let's define a signal `rst_released` which becomes 1 after CHAINS cycles of deassertion.
    // Then sync_rst_o = rst_active | rst_released? No, if rst_active is 1, rst_released should be 0 or don't care.
    // If rst_active is 0, we wait for rst_released to become 1.
    // So: sync_rst_o = rst_active | rst_released;
    // But rst_released should be 0 while reset is active.
    
    // Let's build a chain that counts down from CHAINS when reset is active?
    // Or simpler: A chain of flip-flops that are cleared by reset.
    // When reset is active, all flip-flops are 0.
    // When reset deasserts, we want to wait CHAINS cycles.
    // We can use a counter that starts at CHAINS when reset deasserts? No, we don't have a "deassert" pulse easily.
    
    // Standard CDC Reset Release Synchronizer:
    // Use a chain of flip-flops. The output of the chain is the synchronized reset.
    // To handle the immediate assertion requirement:
    // We can drive the output directly from the input reset, but we must ensure the chain doesn't fight it.
    // Actually, the most robust way is:
    // sync_rst_o = rst_active | (synchronized_release_signal);
    // Where synchronized_release_signal is 1 only after the reset has been deasserted for CHAINS cycles.
    // And synchronized_release_signal is 0 when reset is active.
    
    // How to generate synchronized_release_signal?
    // We need a chain that is 0 when reset is active, and transitions to 1 after CHAINS cycles of deassertion.
    // We can use a counter that is cleared by reset and counts up when reset is inactive.
    // When counter == CHAINS, we assert the release signal.
    // But a counter might glitch if reset toggles rapidly.
    
    // Better approach: A chain of flip-flops acting as a delay line for the "Reset Deassertion" event.
    // Let's assume the reset is active high.
    // We want to detect the edge where reset goes 1->0.
    // We can use a chain of flip-flops to synchronize this edge.
    // However, the simplest and most area-efficient method for reset release is a chain of flip-flops
    // that are cleared by the reset, and the output is taken from the last stage.
    // But if we just clear them, they stay 0. We need them to go to 1.
    
    // Correct Logic for Reset Release Synchronizer:
    // 1. The reset signal is passed through a chain of flip-flops to synchronize the *release* event.
    // 2. Since the reset must be asserted immediately, we can use the input reset directly for the assertion part.
    // 3. For the release part, we need to ensure that the reset has been deasserted for CHAINS cycles.
    //    We can use a counter that is cleared by the reset and increments every clock cycle when reset is low.
    //    When the counter reaches CHAINS, we assert a "release_ready" signal.
    //    Then sync_rst_o = rst_active | release_ready.
    //    Wait, if rst_active is 1, release_ready should be 0. If rst_active is 0, release_ready becomes 1 after delay.
    //    This works.
    
    // Let's refine the counter approach:
    // counter is cleared by rst_active.
    // counter increments every clk when !rst_active.
    // When counter == CHAINS, release_ready = 1.
    // sync_rst_o = rst_active | release_ready.
    // Is this safe?
    // If rst_active goes 1->0, counter starts counting. After CHAINS cycles, release_ready goes 1.
    // If rst_active goes 0->1, counter is cleared to 0. release_ready goes 0 (assuming we clear it too).
    // This seems correct and robust.
    
    // However, there is a nuance: "sync_rst_o must follow assertion of async_rst_i immediately."
    // With the OR logic, if rst_active is 1, sync_rst_o is 1. Immediate.
    // If rst_active is 0, sync_rst_o depends on release_ready.
    // release_ready is 0 initially. It becomes 1 only after CHAINS cycles of !rst_active.
    // This satisfies the requirement.
    
    // One detail: The counter needs to be reset to 0 when rst_active is 1.
    // Also, release_ready should be 0 when rst_active is 1.
    // So:
    // always @(posedge clk or posedge rst_active) begin
    //     if (rst_active) begin
    //         counter <= 0;
    //         release_ready <= 0;
    //     end else begin
    //         if (counter == (CHAINS - 1)) begin // Assuming CHAINS >= 1
    //             release_ready <= 1;
    //         end else begin
    //             counter <= counter + 1;
    //             release_ready <= 0; // Ensure it's 0 until we hit the limit
    //         end
    //     end
    // end
    // Wait, if CHAINS=2, we want to wait 2 cycles.
    // Cycle 0 (rst=0): counter=0, ready=0
    // Cycle 1 (rst=0): counter=1, ready=0
    // Cycle 2 (rst=0): counter=2, ready=1
    // So we need to count up to CHAINS.
    // But we must be careful with the reset condition.
    // If rst_active is 1, counter=0, ready=0.
    // If rst_active becomes 0:
    //   Next cycle: counter=1, ready=0.
    //   ...
    //   When counter reaches CHAINS, ready=1.
    
    // Let's adjust the counter logic to be precise.
    // We need a counter that counts the number of consecutive clock cycles where reset is inactive.
    // Once it reaches CHAINS, we assert the release.
    // If reset becomes active again, the counter resets to 0 and release is deasserted.
    
    // Implementation details:
    // - Use a wire for the counter to avoid synthesis warnings if possible, or reg.
    // - CHAINS parameter: if CHAINS=1, we wait 1 cycle.
    // - If CHAINS=2, we wait 2 cycles.
    
    // Let's write the code.
    
    reg [CHAINS-1:0] rst_release_counter;
    reg rst_release_ready;
    
    always @(posedge clk or posedge rst_active) begin
        if (rst_active) begin
            rst_release_counter <= 0;
            rst_release_ready <= 0;
        end else begin
            if (rst_release_counter == CHAINS - 1) begin
                rst_release_ready <= 1;
            end else begin
                rst_release_counter <= rst_release_counter + 1;
                rst_release_ready <= 0;
            end
        end
    end
    
    // Output assignment
    assign sync_rst_o = rst_active | rst_release_ready;

endmodule<|im_end|>
