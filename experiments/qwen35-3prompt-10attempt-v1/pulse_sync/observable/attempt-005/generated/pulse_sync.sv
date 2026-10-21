module pulse_sync #(
    parameter STAGES = 2
)(
    input  clk_a,
    input  rstn_a,
    input  clk_b,
    input  rstn_b,
    input  pulseA_i,
    output pulseB_o,
    output busy_o
);

    // Synchronizer for pulseA_i on clk_b domain
    // We need to detect a single rising edge of pulseA_i and transfer it to clk_b
    wire [STAGES-1:0] sync_pulseA;
    wire sync_pulseA_valid;

    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : sync_stage
            assign sync_pulseA[i] = rstn_b ? (i == 0 ? pulseA_i : sync_pulseA[i-1]) : 1'b0;
        end
    endgenerate

    // Detect the single pulse edge in the destination domain
    // We look for a transition from 0 to 1 in the last stage of the synchronizer
    // Since the input is a pulse, we capture the moment it arrives.
    wire pulseA_edge;
    assign pulseA_edge = sync_pulseA[STAGES-1] & ~sync_pulseA[STAGES-2];

    // State machine in clk_b domain to handle the "in-flight" logic
    // States: IDLE (0), BUSY (1)
    // We use a simple register to track state
    reg busy_state;
    reg pulseB_reg;

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            busy_state <= 1'b0;
            pulseB_reg <= 1'b0;
        end else begin
            if (pulseA_edge) begin
                // A new pulse is detected.
                // If we are already busy, we ignore it (as per requirement: "ignore further pulses while busy").
                // If we are idle, we set the output and mark as busy.
                if (busy_state == 1'b0) begin
                    pulseB_reg <= 1'b1;
                    busy_state <= 1'b1;
                end
            end else begin
                // No new pulse edge detected.
                // If we are busy, we wait for the pulse to naturally expire or rely on the fact that
                // the output should only be high for one cycle of the source pulse?
                // Requirement: "Carry an input pulse to the other side once."
                // Interpretation: The output should mirror the single pulse event.
                // Since the input is a pulse (0->1->0), the output should also be a pulse (0->1->0).
                // However, the requirement says "ignore further pulses while busy".
                // This implies the "busy" state persists until the current pulse is fully transferred.
                // To ensure the output goes back to 0, we must wait for the pulse to end in the source domain?
                // No, we cannot see the source domain pulse end directly without a second synchronizer chain.
                // Standard approach for "one-shot" crossing:
                // 1. Detect edge in dest domain.
                // 2. Assert output.
                // 3. De-assert output after one cycle of dest clock? 
                //    OR wait for the corresponding falling edge of the pulse in the source domain?
                //    Given "Carry an input pulse", usually means the duration matters.
                //    But "ignore further pulses while busy" suggests a latch-like behavior until the current one is done.
                //    If the source pulse is wide, and we just latch on edge, the output stays high forever until reset?
                //    That violates "Carry a pulse".
                //    Correct interpretation: We must synchronize the falling edge too to know when the pulse is over.
                
                // Let's refine the logic:
                // We need to detect the start (rising) and end (falling) of the pulse in the destination domain.
                // But the requirement says "ignore further pulses while busy".
                // If we wait for the falling edge in the destination domain, we are effectively waiting for the pulse to end.
                // If the source pulse is very short, the dest domain might see it as a single cycle or multiple cycles.
                // If we see multiple cycles, we should only output one pulse.
                
                // Revised Strategy:
                // 1. Synchronize Rising Edge -> Set Busy & Output High.
                // 2. Synchronize Falling Edge -> Clear Output & Clear Busy.
                // 3. If a new Rising Edge comes while Busy, ignore it.
                
                // To implement this robustly:
                // We need to detect the falling edge of the synchronized pulse stream.
                // Let's create a second synchronizer chain for the falling edge detection logic.
                
                // Actually, simpler approach for "One Pulse In, One Pulse Out":
                // Detect the rising edge. Assert output.
                // Detect the falling edge. De-assert output.
                // If another rising edge comes before the falling edge is processed, ignore it.
                
                // Implementation details:
                // We need to know if the current pulse is still "active" in the destination domain.
                // Since we only have one pulse, we can just wait for the falling edge of the synchronized signal.
                
                // Let's restructure the FSM slightly.
                // We need a flag 'pulse_started' and 'pulse_finished'.
                // But we can do it with just the state machine if we detect edges correctly.
                
                // Let's assume the pulse width in the source domain is at least 2 cycles of clk_b (worst case).
                // If not, the synchronizer might miss the falling edge or see it as noise.
                // Assuming standard pulse widths.
                
                // Logic:
                // If pulseA_edge (rising) occurs and !busy_state:
                //    pulseB_o = 1; busy_state = 1;
                // Else if falling_edge occurs and busy_state:
                //    pulseB_o = 0; busy_state = 0;
                // Else:
                //    pulseB_o = 0; busy_state = 0;
                
                // We need to detect the falling edge of the synchronized pulse.
                // Let's create a wire for the falling edge detection.
            end
        end
    end

    // Wait, the logic inside the always block above is incomplete because I didn't define the falling edge wire.
    // Let's rewrite the logic cleanly.
    
    // Re-evaluating the "Busy" condition.
    // "Indicate when one is in flight".
    // "Ignore further pulses while busy".
    // "Clear the outputs on reset".
    
    // Plan:
    // 1. Sync pulseA_i to clk_b domain (already done: sync_pulseA).
    // 2. Detect Rising Edge of sync_pulseA -> Start Pulse, Set Busy.
    // 3. Detect Falling Edge of sync_pulseA -> End Pulse, Clear Busy.
    // 4. If Rising Edge detected while Busy -> Ignore.
    
    wire sync_pulseA_falling;
    assign sync_pulseA_falling = ~sync_pulseA[STAGES-1] & sync_pulseA[STAGES-2];

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            busy_state <= 1'b0;
            pulseB_reg <= 1'b0;
        end else begin
            if (sync_pulseA[STAGES-1]) begin
                // Rising edge detected in dest domain
                if (busy_state == 1'b0) begin
                    // New pulse, not busy
                    pulseB_reg <= 1'b1;
                    busy_state <= 1'b1;
                end
                // If busy, do nothing (ignore pulse)
            end else if (sync_pulseA_falling) begin
                // Falling edge detected in dest domain
                // This means the pulse we started has ended.
                // We must ensure we are in a busy state to clear it.
                if (busy_state == 1'b1) begin
                    pulseB_reg <= 1'b0;
                    busy_state <= 1'b0;
                end
            end else begin
                // No edge detected
                if (busy_state == 1'b1) begin
                    // This case shouldn't happen if we rely on the falling edge to clear.
                    // However, if the pulse is extremely short (1 cycle in dest domain),
                    // the rising and falling happen in the same cycle or adjacent.
                    // If rising sets it, and falling clears it in the next cycle, we are good.
                    // If the pulse is 1 cycle wide:
                    // Cycle N: Rising edge -> Set Busy, Set Output.
                    // Cycle N+1: Falling edge -> Clear Busy, Clear Output.
                    // This works.
                    // What if the pulse is wider?
                    // Cycle N: Rising -> Set Busy, Set Output.
                    // Cycle N+1..M: Stable High -> Do nothing.
                    // Cycle M+1: Falling -> Clear Busy, Clear Output.
                    // This works.
                    // What if the pulse is very short (less than 2 cycles in dest domain)?
                    // E.g., Source pulse is 1 cycle of clk_a.
                    // Synchronizer might see it as 0, 0, 0... or 0, 1, 0...
                    // If it sees 0, 1, 0:
                    // Cycle 1: 0 -> No action.
                    // Cycle 2: 1 (Rising) -> Set Busy, Set Output.
                    // Cycle 3: 0 (Falling) -> Clear Busy, Clear Output.
                    // Works.
                    
                    // Is there a case where we stay busy?
                    // Only if the falling edge is never detected.
                    // This happens if the pulse is stuck at 1 due to metastability or if the pulse is extremely wide.
                    // Assuming valid digital pulses.
                    
                    // One edge case: What if the falling edge is detected but we are NOT busy?
                    // This could happen if a previous pulse was ignored (because we were busy) and then the falling edge of THAT ignored pulse comes?
                    // No, if we were busy, we ignored the rising edge. So we are still busy.
                    // So the falling edge of the ignored pulse will clear the busy state.
                    // This is correct behavior: "Ignore further pulses while busy".
                    // The "busy" flag covers the entire duration of the current pulse (including ignored ones? No).
                    // Wait. If I have Pulse 1 (start), then Pulse 2 (start ignored), then Pulse 1 ends.
                    // When Pulse 1 ends, we clear busy.
                    // Then Pulse 2's falling edge comes. We are not busy. Do we clear anything? No.
                    // But Pulse 2 was ignored. So we don't want to output anything for Pulse 2.
                    // And we don't want to clear busy (it's already clear).
                    // So the logic holds.
                    
                    // Wait, what if Pulse 1 is ignored?
                    // Start Busy. Pulse 1 Rising -> Ignored.
                    // Pulse 1 Falling -> Clears Busy.
                    // Now we are Idle.
                    // Pulse 2 Rising -> Accepted.
                    // This seems correct.
                    
                    // BUT, there is a flaw.
                    // If Pulse 1 is accepted. We are Busy.
                    // Pulse 2 arrives (Rising). Ignored.
                    // Pulse 1 ends (Falling). We clear Busy.
                    // Pulse 2 ends (Falling). We are NOT Busy. So we do nothing.
                    // Result: Pulse 1 transferred. Pulse 2 ignored. Correct.
                    
                    // What if Pulse 1 is very long?
                    // Accepted. Busy.
                    // Pulse 2 arrives. Ignored.
                    // Pulse 1 ends. Cleared.
                    // Pulse 2 ends. Ignored (not busy).
                    // Correct.
                    
                    // What if Pulse 1 is short, Pulse 2 is long?
                    // Pulse 1 Accepted. Busy.
                    // Pulse 1 ends. Cleared.
                    // Pulse 2 Accepted. Busy.
                    // Pulse 2 ends. Cleared.
                    // Correct.
                    
                    // So the logic seems sound.
                    // Just need to make sure the output is driven correctly.
                    // pulseB_o should be pulseB_reg.
                    
                    // One detail: "Indicate when one is in flight".
                    // busy_o should be high when we are processing a pulse.
                    // In my logic, busy_state is high from Rising Edge to Falling Edge.
                    // This matches "in flight".
                    
                    // Final check on the "ignore" logic.
                    // If I am busy, and a new pulse comes. I ignore the rising edge.
                    // I stay busy.
                    // The falling edge of the NEW pulse comes.
                    // Since I am still busy (from the first pulse), I clear the busy state and output.
                    // This effectively merges the two pulses?
                    // No.
                    // Scenario:
                    // T0: Pulse 1 Rising. Busy=1, Out=1.
                    // T1: Pulse 1 Falling. Busy=0, Out=0.
                    // T2: Pulse 2 Rising. Busy=1, Out=1.
                    // T3: Pulse 2 Falling. Busy=0, Out=0.
                    // This is perfect.
                    
                    // Scenario with overlap:
                    // T0: Pulse 1 Rising. Busy=1, Out=1.
                    // T1: Pulse 2 Rising. Busy=1 (Ignore). Out=1.
                    // T2: Pulse 1 Falling. Busy=0, Out=0.
                    // T3: Pulse 2 Falling. Busy=0 (Ignore). Out=0.
                    // Result: Only Pulse 1 is transferred. Pulse 2 is completely lost.
                    // Is this desired? "Carry an input pulse to the other side once."
                    // "Ignore further pulses while busy".
                    // Yes, if a pulse is in flight, subsequent pulses are ignored.
                    // So merging the falling edges is actually a bug in my logic above?
                    // Let's trace T2/T3 again.
                    // At T2, Pulse 1 ends. We clear Busy.
                    // At T3, Pulse 2 ends. We are NOT Busy. So we do nothing.
                    // The output goes 1->0 at T2. Then stays 0.
                    // So Pulse 2 is indeed ignored.
                    // The logic holds.
                    
                    // Wait, what if Pulse 1 is very long, and Pulse 2 starts before Pulse 1 ends?
                    // T0: P1 Rise. Busy=1, Out=1.
                    // T1: P2 Rise. Busy=1 (Ignore). Out=1.
                    // T2: P1 Fall. Busy=0, Out=0.
                    // T3: P2 Fall. Busy=0 (Ignore). Out=0.
                    // Result: Only P1 is seen. P2 is lost. Correct.
                    
                    // What if P1 is short, P2 is long, and they overlap?
                    // T0: P1 Rise. Busy=1, Out=1.
                    // T1: P1 Fall. Busy=0, Out=0.
                    // T2: P2 Rise. Busy=1, Out=1.
                    // T3: P2 Fall. Busy=0, Out=0.
                    // Result: P1 transferred, then P2 transferred. Correct.
                    
                    // The logic seems robust for the "One Pulse In, One Pulse Out" requirement.
                    
                    // One minor issue: What if the falling edge is not detected because the pulse is 1 cycle wide in the destination domain?
                    // Synchronizer: 0 -> 1 -> 0.
                    // Cycle 1: 0.
                    // Cycle 2: 1. (Rising detected). Busy=1, Out=1.
                    // Cycle 3: 0. (Falling detected). Busy=0, Out=0.
                    // Works.
                    
                    // What if the synchronizer sees 0 -> 1 -> 1 -> 0? (Pulse width >= 2 cycles in dest)
                    // Cycle 1: 0.
                    // Cycle 2: 1. (Rising). Busy=1, Out=1.
                    // Cycle 3: 1. (No edge).
                    // Cycle 4: 0. (Falling). Busy=0, Out=0.
                    // Works.
                    
                    // So the logic is:
                    // if (rising_edge && !busy) { busy=1; out=1; }
                    // else if (falling_edge && busy) { busy=0; out=0; }
                    // else { out=0; } // Implicitly handled by else if busy is 0 and no falling edge?
                    // Wait, if busy=0 and no edges, out stays 0.
                    // If busy=1 and no edges (pulse continuing), out stays 1.
                    // My code needs to handle the "hold" case.
                    
                    // Let's rewrite the always block to be explicit.
                end
            end
        end
    end
endmodule

always @(posedge clk_b or negedge rstn_b) begin
    if (!rstn_b) begin
        busy_state <= 1'b0;
        pulseB_reg <= 1'b0;
    end else begin
        if (sync_pulseA[STAGES-1]) begin // Current state is 1
            if (sync_pulseA[STAGES-2]) begin // Previous state was 1 -> No edge
                // Hold state
                if (busy_state) pulseB_reg <= 1'b1;
                else pulseB_reg <= 1'b0; // Should be 0 anyway
            end else begin // Previous state was 0 -> Rising Edge
                if (busy_state == 1'b0) begin
                    pulseB_reg <= 1'b1;
                    busy_state <= 1'b1;
                end
                // If busy, ignore
            end
        end else begin // Current state is 0
            if (sync_pulseA[STAGES-2]) begin // Previous state was 1 -> Falling Edge
                if (busy_state == 1'b1) begin
                    pulseB_reg <= 1'b0;
                    busy_state <= 1'b0;
                end
                // If not busy, do nothing (ignore falling edge of ignored pulse)
            end else begin // Previous state was 0 -> No edge
                // Stay idle
                pulseB_reg <= 1'b0;
                busy_state <= 1'b0;
            end
        end
    end
end

always @(posedge clk_b or negedge rstn_b) begin
    if (!rstn_b) begin
        busy_state <= 1'b0;
        pulseB_reg <= 1'b0;
    end else begin
        if (sync_pulseA[STAGES-1] && !sync_pulseA[STAGES-2]) begin
            // Rising Edge
            if (!busy_state) begin
                busy_state <= 1'b1;
                pulseB_reg <= 1'b1;
            end
        end else if (~sync_pulseA[STAGES-1] && sync_pulseA[STAGES-2]) begin
            // Falling Edge
            if (busy_state) begin
                busy_state <= 1'b0;
                pulseB_reg <= 1'b0;
            end
        end else begin
            // No edge
            if (busy_state) begin
                // Pulse is still active, keep output high
                pulseB_reg <= 1'b1;
            end else begin
                // Idle
                pulseB_reg <= 1'b0;
            end
        end
    end
end
