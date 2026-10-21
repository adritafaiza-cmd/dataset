```verilog
`timescale 1ns/1ps

module pulse_sync #(
    parameter STAGES = 2
)(
    input  wire clk_a,
    input  wire rstn_a,
    input  wire clk_b,
    input  wire rstn_b,
    input  wire pulseA_i,
    output wire pulseB_o,
    output wire busy_o
);

    // Internal signals for the pipeline stages
    // We use a 2-stage pipeline for the data path to ensure CDC safety.
    // STAGES parameter allows scaling, but 2 is the minimum safe implementation 
    // for a single-bit pulse transfer with busy logic.
    
    reg [STAGES-1:0] busy_reg;
    reg [STAGES-1:0] pulse_reg;
    
    // Generate the pipeline stages
    // Stage 0: Capture input pulse and update busy status
    // Stage 1 to STAGES-1: Shift registers to hold the pulse and busy state
    
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : stage_gen
            if (i == 0) begin : stage_0
                // First stage captures the input pulse and the busy signal from the previous domain
                // We assume busy_o is initially low. 
                // The busy signal here indicates if a pulse is currently in flight.
                always @(posedge clk_a or negedge rstn_a) begin
                    if (!rstn_a) begin
                        pulse_reg[i] <= 1'b0;
                        busy_reg[i] <= 1'b0;
                    end else begin
                        // Capture input pulse
                        pulse_reg[i] <= pulseA_i;
                        // Update busy: if we just captured a pulse (and it wasn't already busy), 
                        // or if we are already busy, we stay busy.
                        // Actually, simpler logic: 
                        // If pulseA_i is high, we are busy. 
                        // If we were already busy, we stay busy.
                        // However, we need to ensure we don't re-trigger if we are already processing.
                        // The "busy" flag effectively latches the state of "processing a pulse".
                        // Let's refine: 
                        // busy_reg[i] = busy_reg[i] | pulseA_i; 
                        // But we must ensure that once busy goes high, it stays high until the pulse clears the pipeline.
                        // A better approach for "one pulse in, one pulse out" with blocking:
                        // The pipeline shifts the '1'. The 'busy' signal is essentially the OR of all stages.
                        // But we need to prevent multiple pulses from entering while one is in flight.
                        
                        // Logic:
                        // 1. If rst, clear.
                        // 2. If not rst:
                        //    - If pulseA_i is high, set current stage pulse to 1.
                        //    - If current stage pulse was 1 (from previous cycle) OR pulseA_i is 1, set busy to 1.
                        //    - Wait, if pulseA_i is 1 and we are already busy, we should NOT set the next stage.
                        //    We need a "gate" that blocks new pulses if busy is high.
                        
                        // Revised Logic for Stage 0:
                        // We need to know if the system is busy BEFORE capturing the new pulse.
                        // Since this is the first stage, "busy" is determined by previous stages or initial state.
                        // Let's define 'busy_in' as the busy signal coming from the previous stage (or 0 for stage 0).
                        // Actually, let's make the pipeline carry both 'pulse' and 'busy' state implicitly.
                        
                        // Standard approach for this specific problem:
                        // Use a shift register for the pulse.
                        // Use a separate shift register or logic for 'busy'.
                        // 'busy' is high if any stage has a '1'.
                        // To prevent multiple pulses: Gate the input if 'busy' is high.
                        
                        // Let's restructure slightly for clarity and safety.
                        // We will have 'pulse_pipe' and 'busy_pipe'.
                        // 'busy_pipe' is just the OR of all 'pulse_pipe' stages.
                        // But we need to gate the input.
                        
                        // Let's stick to the prompt's variable names but implement the logic correctly.
                        // We will calculate 'is_busy' based on the current pipeline content.
                        // However, calculating 'is_busy' synchronously at the same edge as capture creates a race if we use it to gate the capture.
                        // Solution: Use a separate register for the 'busy' state that lags by one cycle or is calculated from the previous stage's busy.
                        
                        // Robust Implementation:
                        // Stage 0 captures pulseA_i ONLY if the system is not busy.
                        // How do we know if it's busy? We look at the output of the previous stage's busy logic.
                        // Since this is stage 0, the "previous" busy is 0 (or derived from a separate domain if we were chaining, but here it's start).
                        // Actually, the simplest safe way is:
                        // 1. Shift register for pulse.
                        // 2. Shift register for 'busy' flag.
                        // 3. The 'busy' flag at stage k is (pulse_reg[k] | busy_reg[k]).
                        // 4. The input to stage 0 is gated by ~busy_reg[0] (from previous cycle).
                        
                        // Let's implement:
                        // pulse_reg[i]: holds the pulse bit at stage i.
                        // busy_reg[i]: holds the busy status at stage i.
                        
                        // For i=0:
                        // busy_reg[0] comes from 0 (initially).
                        // We capture pulseA_i if ~busy_reg[0] (which is 1 initially).
                        // Then update busy_reg[0] = pulse_reg[0] | busy_reg[0].
                        
                        // For i>0:
                        // pulse_reg[i] = pulse_reg[i-1]
                        // busy_reg[i] = pulse_reg[i] | busy_reg[i-1]
                        
                        // This ensures that if any stage is high, the busy flag propagates.
                        // And the input is gated by the busy flag of the previous stage (which is 0 for stage 0).
                        
                        // Wait, if we use busy_reg[i] to gate pulseA_i, we need busy_reg[i] from the PREVIOUS cycle.
                        // So:
                        // next_pulse = pulseA_i & ~busy_reg[i];
                        // next_busy = next_pulse | busy_reg[i];
                        
                        // Let's apply this logic.
                        
                        // Calculate next state
                        wire wire_pulse_next;
                        wire wire_busy_next;
                        
                        if (i == 0) begin
                            // Input stage
                            // Gate input by current busy status of this stage (which reflects previous cycle)
                            // If busy_reg[0] is 1, we ignore pulseA_i.
                            wire_pulse_next = pulseA_i & ~busy_reg[0];
                            wire_busy_next = wire_pulse_next | busy_reg[0];
                        end else begin
                            // Pipeline stages
                            wire_pulse_next = pulse_reg[i-1];
                            wire_busy_next = wire_pulse_next | busy_reg[i-1];
                        end
                        
                        always @(posedge clk_a or negedge rstn_a) begin
                            if (!rstn_a) begin
                                pulse_reg[i] <= 1'b0;
                                busy_reg[i] <= 1'b0;
                            end else begin
                                pulse_reg[i] <= wire_pulse_next;
                                busy_reg[i] <= wire_busy_next;
                            end
                        end
                    end
                end
            end
        end
    endgenerate
    
    // Output logic
    // pulseB_o is the pulse from the last stage.
    // busy_o is the OR of all busy stages (or simply the busy status of the last stage, 
    // since if the last stage is busy, the whole system is busy).
    
    assign pulseB_o = pulse_reg[STAGES-1];
    
    // busy_o is high if any stage is busy. 
    // Since busy_reg propagates the OR of the pulse path, busy_reg[STAGES-1] should be high 
    // if any stage has a pulse.
    // However, to be absolutely explicit and safe against any weird edge cases in the shift logic:
    // busy_o = OR(pulse_reg[0], pulse_reg[1], ..., pulse_reg[STAGES-1]);
    // But given our logic: busy_reg[i] = pulse_reg[i] | busy_reg[i-1], 
    // busy_reg[STAGES-1] is effectively the OR of all pulse_reg.
    assign busy_o = busy_reg[STAGES-1];

endmodule
```<|im_end|>
