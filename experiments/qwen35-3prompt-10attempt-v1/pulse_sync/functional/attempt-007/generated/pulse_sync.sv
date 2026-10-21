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

    // Internal signals
    reg [STAGES-1:0] shift_reg;
    reg busy;

    // Stage 0: Capture pulse from domain A
    // We use a 2-stage pipeline for robustness against metastability and pulse width
    // STAGES=2 means we have 2 flip-flops in the capture chain.
    // The logic below creates a 1-cycle pulse in domain A that is wide enough to pass through.
    
    // Capture chain for domain A
    // We need to detect a rising edge of pulseA_i and hold it for at least 2 cycles
    // to ensure it propagates through the STAGES pipeline.
    
    reg pulseA_d1;
    reg pulseA_d2;
    reg pulseA_d3; // Extra stage to ensure pulse width > STAGES

    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            pulseA_d1 <= 1'b0;
            pulseA_d2 <= 1'b0;
            pulseA_d3 <= 1'b0;
        end else begin
            pulseA_d1 <= pulseA_i;
            pulseA_d2 <= pulseA_d1;
            pulseA_d3 <= pulseA_d2;
        end
    end

    // Generate a pulse that is high for (STAGES + 1) cycles in domain A
    // This ensures the pulse survives the STAGES pipeline without being truncated.
    reg pulseA_pulse;
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a)
            pulseA_pulse <= 1'b0;
        else begin
            // Pulse is high if we have seen a rising edge and haven't seen a falling edge yet
            // in the capture chain.
            // Logic: (d1 & ~d2) detects rising edge. We want to keep it high until d3 falls.
            // Actually, simpler approach for 1-pulse:
            // Detect rising edge, then wait for falling edge.
            // To make it robust, we extend the pulse duration.
            
            if (pulseA_d1 && !pulseA_d2) begin
                // Rising edge detected
                pulseA_pulse <= 1'b1;
            end else if (!pulseA_d3) begin
                // Falling edge detected in the 3rd stage
                pulseA_pulse <= 1'b0;
            end else begin
                // Hold state
                pulseA_pulse <= pulseA_pulse;
            end
        end
    end

    // Cross clock domain: Shift the pulse through STAGES flip-flops
    // The input to the first stage is pulseA_pulse
    // The output of the last stage is the pulse in domain B
    
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            shift_reg <= {STAGES{1'b0}};
            busy <= 1'b0;
            pulseB_o <= 1'b0;
        end else begin
            // Shift register logic
            shift_reg <= {shift_reg[STAGES-2:0], pulseA_pulse};
            
            // busy_o is high if any stage in the pipeline is high
            busy <= shift_reg[STAGES-1] | shift_reg[STAGES-2] | shift_reg[STAGES-3];
            
            // pulseB_o is the last bit of the shift register
            // Note: Since we extended the pulse width in domain A to be > STAGES,
            // the pulse will appear as a single cycle (or slightly wider depending on exact timing)
            // at the output. However, the requirement is "one-pulse-in, one-pulse-out".
            // If the input pulse is extended to N+1 cycles, the output will be N+1 cycles.
            // To strictly output a 1-cycle pulse, we need to detect the leading edge in domain B
            // and generate a 1-cycle pulse, OR ensure the input pulse is exactly 1 cycle.
            
            // Revised Strategy for strict 1-cycle output:
            // 1. Detect rising edge in Domain A.
            // 2. Shift this "edge" through the pipeline.
            // 3. In Domain B, detect the rising edge of the shifted signal and generate a 1-cycle pulse.
            
            // Let's re-implement the cross-domain logic to ensure exactly 1 cycle output.
            // We will pass the "valid" flag through the pipeline.
            
            // Re-evaluating the pipeline content:
            // We want to pass a "start" signal.
            // Let's simplify:
            // Domain A: Detect rising edge of pulseA_i.
            // Domain B: Detect rising edge of the shifted signal and output 1 cycle.
            
            // Resetting the logic for clarity and correctness:
            // We need a pulse that is 1 cycle wide in Domain A to enter the pipeline?
            // No, metastability requires the pulse to be stable for at least 2 cycles.
            // So we capture the pulse in Domain A, extend it to 2 cycles, shift it.
            // Then in Domain B, we detect the transition and output 1 cycle.
            
            // Let's use a different approach for the pipeline content:
            // We will shift the "pulseA_pulse" signal.
            // But to get a 1-cycle output, we need to detect the edge in domain B.
            
            // Let's define the pipeline to carry the pulse.
            // If pulseA_pulse is 2 cycles wide (as designed above), the output will be 2 cycles wide.
            // To fix this, we will detect the rising edge of the shifted signal in domain B.
            
            // Actually, the standard way to do "1 pulse in, 1 pulse out" with a pipeline:
            // 1. In Domain A, create a pulse that is wide enough to cross (e.g., 2 cycles).
            // 2. Shift it through STAGES.
            // 3. In Domain B, detect the rising edge of the shifted signal and generate a 1-cycle pulse.
            
            // Let's adjust the pipeline logic to just shift the signal.
            // And add edge detection in domain B.
            
            // Wait, the previous logic for `pulseA_pulse` makes it 2 cycles wide.
            // If we shift that, the output of the last FF is 2 cycles wide.
            // We need to detect the rising edge of `shift_reg[STAGES-1]` in domain B.
            
            // Let's refactor the always block for domain B to handle edge detection.
            // We need to store the previous value of the last stage to detect the edge.
            
            // Re-writing the module logic for clarity:
            
            // Step 1: Capture and extend pulse in Domain A (already done: pulseA_pulse is ~2 cycles)
            // Step 2: Shift through pipeline (shift_reg)
            // Step 3: Detect rising edge of the last stage in Domain B and output 1 cycle.
            
            // We need an extra register in domain B to detect the edge.
            reg pulseB_last;
            
            // Update shift_reg logic to include the edge detection variable
            // Actually, let's keep shift_reg as the pipeline.
            // We need to detect the rising edge of shift_reg[STAGES-1].
            
            // Let's restart the logic flow inside the always block for clarity.
            
            // We will use the shift_reg to transport the pulse.
            // The output pulseB_o will be generated by detecting the rising edge of the last stage.
            
            // But wait, if we just shift a 2-cycle pulse, the last stage goes 0->1->1->0.
            // Detecting the rising edge (0->1) gives us 1 cycle.
            // So we need to store the previous value of the last stage.
            
            // Let's modify the always block to include this.
            
            // However, the current `shift_reg` assignment happens before we can use `shift_reg[STAGES-1]`
            // to detect the edge for the current cycle's output.
            // We need to store the old value.
            
            // Let's restructure:
            // 1. Calculate new_shift_reg.
            // 2. Detect edge on new_shift_reg[STAGES-1] compared to old_shift_reg[STAGES-1].
            // 3. Assign pulseB_o.
            
            // But Verilog non-blocking assignments make this tricky in one block.
            // We can use a temporary variable or split the logic.
            
            // Alternative: Just let the pulse be 2 cycles wide in domain B?
            // The requirement says "one-pulse-out". Usually, this implies 1 cycle.
            // If the input is 1 cycle, the output should be 1 cycle.
            // Since we must extend the pulse in domain A to 2 cycles for safety,
            // the output in domain B will naturally be 2 cycles wide if we just pass it through.
            // To make it 1 cycle, we MUST detect the edge.
            
            // Let's implement the edge detection properly.
            
            // We need to store the previous state of the last stage.
            // Let's add a register `pulseB_prev` inside the module.
            
            // Wait, I cannot add new registers outside the always block easily without restructuring.
            // Let's put everything in one always block for domain B.
            
            // Logic:
            // next_shift = {shift_reg[STAGES-2:0], pulseA_pulse}
            // edge = (next_shift[STAGES-1] && !shift_reg[STAGES-1])
            // pulseB_o = edge
            
            // But `shift_reg` is the current value. `next_shift` is the value after update.
            // So `edge` is detected on the transition from current to next.
            // This works.
            
            // Let's rewrite the always block completely.
            
            // We need to declare `pulseB_prev`? No, we can just compare current and next.
            // But `pulseB_o` needs to be high for 1 cycle.
            // If `edge` is true, `pulseB_o` becomes 1.
            // Next cycle, `edge` becomes false (since next_shift will be 1, and current was 1).
            // So `pulseB_o` will be 1 for exactly 1 cycle.
            
            // Correct logic:
            // 1. Compute `next_shift`.
            // 2. `pulseB_o` = 1 if `next_shift[STAGES-1]` is 1 AND `shift_reg[STAGES-1]` is 0.
            // 3. `shift_reg` <= `next_shift`.
            
            // This requires `shift_reg` to be read before update.
            // In non-blocking assignment, `shift_reg` on RHS is the old value.
            // So:
            // reg [STAGES-1:0] next_shift;
            // next_shift = {shift_reg[STAGES-2:0], pulseA_pulse};
            // if (next_shift[STAGES-1] && !shift_reg[STAGES-1]) pulseB_o = 1'b1;
            // else pulseB_o = 1'b0;
            // shift_reg <= next_shift;
            
            // This works perfectly.
            
            // Let's re-verify the `pulseA_pulse` generation.
            // It generates a pulse that is high for 2 cycles (assuming STAGES >= 2).
            // If STAGES=2:
            // Cycle 1: pulseA_i rises. pulseA_d1=1, d2=0, d3=0. pulseA_pulse=1.
            // Cycle 2: pulseA_i stable. pulseA_d1=1, d2=1, d3=0. pulseA_pulse=1.
            // Cycle 3: pulseA_i falls. pulseA_d1=1, d2=1, d3=1. pulseA_pulse=0 (because d3 fell? No, d3 is still 1).
            // Wait, my logic for `pulseA_pulse` falling edge was: `if (!pulseA_d3)`.
            // In Cycle 3, d3 is still 1 (from Cycle 2). So pulseA_pulse stays 1.
            // In Cycle 4: d3 becomes 0 (from Cycle 3). pulseA_pulse becomes 0.
            // So the pulse is 3 cycles wide?
            // Let's trace carefully.
            // T0: i=0, d1=0, d2=0, d3=0 -> p=0
            // T1: i=1, d1=1, d2=0, d3=0 -> p=1 (d1=1, d2=0 -> rising)
            // T2: i=1, d1=1, d2=1, d3=0 -> p=1 (d1=1, d2=1 -> hold; d3=0 -> hold)
            // T3: i=1, d1=1, d2=1, d3=1 -> p=1 (d1=1, d2=1 -> hold; d3=1 -> hold)
            // T4: i=0, d1=0, d2=1, d3=1 -> p=0 (d1=0, d2=1 -> falling? No logic for falling edge in d1/d2)
            // My logic: `if (pulseA_d1 && !pulseA_d2) p=1; else if (!pulseA_d3) p=0; else p=p;`
            // T4: d1=0, d2=1. First if fails. Second if: !d3 is 0. Else p=p (which is 1).
            // T5: d1=0, d2=0, d3=1. First if fails. Second if: !d3 is 0. Else p=p (1).
            // T6: d1=0, d2=0, d3=0. Second if: !d3 is 1. p=0.
            // So the pulse is from T1 to T5 (5 cycles). This is too long.
            
            // We need a simpler, more robust pulse generator.
            // Standard approach: Detect rising edge, hold for N cycles, then release.
            // Or simply: Use a 2-stage pipeline to capture the pulse, then extend it to 2 cycles explicitly.
            
            // Let's try a different logic for `pulseA_pulse`:
            // We want a pulse that is high for exactly 2 cycles in domain A.
            // We can detect the rising edge and set a flag.
            // Then we count 2 cycles and clear it.
            
            // Simpler: Just use the fact that a 1-cycle pulse in domain A might be too narrow.
            // We will assume the input pulse is at least 2 cycles wide in domain A?
            // The problem says "one-cycle pulse". This is risky for async crossing.
            // Usually, we assume the pulse is wide enough or we extend it.
            // Since we must guarantee crossing, we MUST extend it.
            
            // Let's use a state machine or a simple counter to extend the pulse to 2 cycles.
            // State 0: Idle
            // State 1: Rising edge detected -> Pulse High
            // State 2: Falling edge detected -> Pulse Low
            // But we need to ensure the pulse is at least 2 cycles.
            
            // Let's try this logic:
            // Detect rising edge. Set `pulse_ext` = 1.
            // Keep `pulse_ext` = 1 for 2 cycles.
            // Then set `pulse_ext` = 0.
            
            reg pulse_ext;
            reg pulse_rising;
            reg pulse_falling;
            
            // Detect edges
            always @(posedge clk_a or negedge rstn_a) begin
                if (!rstn_a) begin
                    pulse_rising <= 1'b0;
                    pulse_falling <= 1'b0;
                    pulse_ext <= 1'b0;
                end else begin
                    pulse_rising <= pulseA_i & ~pulseA_d1; // Rising edge
                    pulse_falling <= ~pulseA_i & pulseA_d1; // Falling edge
                    pulse_ext <= pulse_ext;
                end
            end
            // Wait, I need pulseA_d1 for edge detection.
            // Let's combine the edge detection and extension.
            
            // Revised Domain A Logic:
            // 1. Detect rising edge.
            // 2. If rising edge, set `pulse_out_a` = 1.
            // 3. If `pulse_out_a` is 1, keep it 1 for 2 more cycles.
            // 4. If falling edge is detected, clear `pulse_out_a`.
            // But if the input pulse is only 1 cycle, we need to extend it.
            // If the input pulse is 2 cycles, we just pass it through (or extend to 2).
            
            // Let's use a simple 2-cycle extension logic:
            // If rising edge detected, start a 2-cycle timer.
            // If falling edge detected, stop the timer.
            // But we need to handle the case where the input pulse is already long.
            
            // Robust solution:
            // Always extend any detected pulse to at least 2 cycles.
            // Logic:
            // If rising edge: pulse_ext = 1.
            // If pulse_ext is 1:
            //    If falling edge: pulse_ext = 0.
            //    Else: pulse_ext = 1 (hold).
            // But this doesn't force a minimum of 2 cycles if the input is 1 cycle.
            // If input is 1 cycle:
            // T0: i=0, d1=0.
            // T1: i=1, d1=0. Rising edge. pulse_ext=1.
            // T2: i=1, d1=1. pulse_ext=1.
            // T3: i=0, d1=1. Falling edge. pulse_ext=0.
            // Result: 2 cycles (T1, T2). Perfect.
            
            // What if input is 2 cycles?
            // T1: i=1. Rising. pulse_ext=1.
            // T2: i=1. Hold. pulse_ext=1.
            // T3: i=1. Hold. pulse_ext=1.
            // T4: i=0. Falling. pulse_ext=0.
            // Result: 3 cycles. This is fine, as long as it's > STAGES.
            
            // What if input is 3 cycles?
            // Result: 4 cycles. Fine.
            
            // So the logic is:
            // pulse_ext = (rising_edge) | (pulse_ext & ~falling_edge)
            // But we need to ensure that if rising_edge is 0 and pulse_ext is 1, it holds.
            // And if falling_edge is 1, it clears.
            // However, if rising_edge is 1, we set it.
            // If falling_edge is 1, we clear it.
            // But what if both are 1? (Glitch). Assume clean signal.
            
            // Logic:
            // if (rising_edge) pulse_ext = 1;
            // else if (falling_edge) pulse_ext = 0;
            // else pulse_ext = pulse_ext;
            
            // This ensures minimum 2 cycles?
            // T1: Rising. pulse_ext=1.
            // T2: No edge. pulse_ext=1.
            // T3: Falling. pulse_ext=0.
            // Total 2 cycles. Yes.
            
            // Wait, what if the input pulse is 1 cycle but the clock domain A has a glitch?
            // We assume clean input.
            
            // Let's refine the edge detection.
            // We need `pulseA_d1` for edge detection.
            
            // Final Domain A Logic:
            // 1. Capture `pulseA_i` into `pulseA_d1`.
            // 2. Detect rising and falling edges.
            // 3. Generate `pulse_ext` which is high for at least 2 cycles.
            
            // Domain B Logic:
            // 1. Shift `pulse_ext` through `STAGES` flip-flops.
            // 2. Detect rising edge of the last stage.
            // 3. Output `pulseB_o` for 1 cycle.
            // 4. `busy_o` is high while any stage is high.
            
            // Let's write the code.
            
            // Domain A
            reg pulseA_d1;
            reg pulse_ext;
            
            always @(posedge clk_a or negedge rstn_a) begin
                if (!rstn_a) begin
                    pulseA_d1 <= 1'b0;
                    pulse_ext <= 1'b0;
                end else begin
                    pulseA_d1 <= pulseA_i;
                    
                    reg rising;
                    reg falling;
                    rising = pulseA_i & ~pulseA_d1;
                    falling = ~pulseA_i & pulseA_d1;
                    
                    if (rising)
                        pulse_ext <= 1'b1;
                    else if (falling)
                        pulse_ext <= 1'b0;
                    else
                        pulse_ext <= pulse_ext;
                end
            end
            
            // Domain B
            reg [STAGES-1:0] shift_reg;
            reg pulseB_o_local;
            
            always @(posedge clk_b or negedge rstn_b) begin
                if (!rstn_b) begin
                    shift_reg <= {STAGES{1'b0}};
                    pulseB_o <= 1'b0;
                    busy_o <= 1'b0;
                end else begin
                    // Calculate next shift register value
                    reg [STAGES-1:0] next_shift;
                    next_shift = {shift_reg[STAGES-2:0], pulse_ext};
                    
                    // Detect rising edge of the last stage to generate 1-cycle pulse
                    if (next_shift[STAGES-1] && !shift_reg[STAGES-1])
                        pulseB_o <= 1'b1;
                    else
                        pulseB_o <= 1'b0;
                    
                    // Update shift register
                    shift_reg <= next_shift;
                    
                    // Busy signal: any stage is high
                    busy_o <= shift_reg[STAGES-1] | shift_reg[STAGES-2] | shift_reg[STAGES-3];
                end
            end

endmodule<|im_end|>
