module data_sync #(
    parameter STAGES = 2,
    parameter DWIDTH = 8
)(
    input                  clk,
    input                  rstn,
    input  [DWIDTH-1:0]    din,
    input                  dready_i,
    output reg [DWIDTH-1:0] dout,
    output reg             dready_o
);

    // Internal state for the FIFO-like structure
    // We need to store the data and the ready status of the previous stage
    // to ensure coherent transfer across multiple stages.
    
    reg [DWIDTH-1:0] data_reg [STAGES-1:0];
    reg ready_reg [STAGES-1:0];
    
    // Logic to determine if the input is ready to be captured
    // The input is ready when dready_i is high AND the first stage buffer is not full (or simply when we can push)
    // Since this is a simple synchronizer chain, we assume the producer pushes whenever dready_i is high.
    // However, to prevent overwriting valid data if the consumer is slow, we typically check the last stage's ready.
    // But the prompt asks to bring the value in coherently. 
    // Standard approach: Push data into stage 0 if dready_i is high.
    // Then propagate data and ready signals through the chain.
    
    // Let's refine the logic:
    // Stage 0 captures din when dready_i is high.
    // Stage N captures data from Stage N-1.
    // dready_o is high when Stage STAGES-1 has valid data and is ready to be read.
    // To handle backpressure or ensure coherence, we usually chain the 'ready' signal backwards.
    // If the last stage is not ready (dready_i low), we should not push new data into stage 0?
    // Actually, the standard synchronizer pattern for "ready" indication is:
    // 1. Capture data on rising edge of clk.
    // 2. Propagate data forward.
    // 3. Propagate ready backward (or use a flag indicating if the chain is full).
    
    // Given the interface, dready_i indicates the source is ready to send.
    // dready_o indicates the destination (this module) is ready to accept.
    // We want to output the data when it has passed through STAGES.
    
    // Implementation Strategy:
    // We will use a shift-register style approach.
    // data_reg[0] captures din.
    // data_reg[i] captures data_reg[i-1].
    // ready_reg[i] indicates if data_reg[i] is valid.
    // dready_o is ready_reg[STAGES-1].
    
    // Backpressure logic:
    // If dready_i is high, we can potentially push data.
    // However, if the chain is full (i.e., the last stage has valid data and we are waiting for it to be consumed),
    // we might want to stop pushing to avoid overwriting.
    // But in a simple synchronizer where dready_i is an input from the *source* domain, 
    // and we are synchronizing *into* the local domain, the constraint is usually:
    // "When dready_i is high, capture din."
    // "When the last stage is ready (dready_o), the consumer can read dout."
    // To ensure no data loss if dready_i stays high while dready_o is low (slow consumer),
    // we should only capture din if the first stage is not "full" or if we have a mechanism to stall.
    // Since we don't have an explicit 'full' flag output, we rely on the depth.
    // With STAGES=2, if we push every time dready_i is high, we might lose data if the consumer is very slow?
    // Actually, the standard synchronizer assumes the producer stops pushing if the consumer is not ready.
    // Here, dready_i is the signal saying "I am ready to send". 
    // If the consumer (this module) is not ready (dready_o low), the producer should ideally stop asserting dready_i.
    // However, to be safe against glitches or slow consumers, we can implement a simple backpressure:
    // Only capture din if the first stage is not already holding valid data that hasn't moved?
    // No, that's not how FIFOs work.
    
    // Correct interpretation for a synchronizer chain:
    // 1. On every clock edge, shift data forward.
    // 2. If dready_i is high, load new data into the first stage (overwriting old if necessary? No, that loses data).
    //    We need to ensure we don't overwrite valid data that hasn't been consumed yet.
    //    But in a simple synchronizer, we assume the producer respects the ready signal.
    //    If dready_o is low, the producer should not assert dready_i.
    //    Therefore, we can simply load din into stage 0 whenever dready_i is high.
    //    Wait, if dready_i is high, we load. If dready_i is low, we hold.
    //    This works if the producer is compliant.
    
    // Let's add a safety check: Only load into stage 0 if the chain is not "full".
    // How do we know if it's full? If the last stage has valid data, it's not necessarily full, 
    // it just means there is data in transit.
    // Actually, the standard implementation for this specific problem (synchronizing a stream) is:
    // - Shift register of depth STAGES.
    // - Load new data into the head if dready_i is high.
    // - BUT, we must ensure we don't overwrite data that is still in the pipeline if the consumer is slow.
    // - Since we don't have a 'full' output, we assume the producer handles backpressure via dready_o.
    // - However, to be robust, we can check if the last stage has valid data. If it does, and dready_i is high,
    //   we might overwrite the head, causing the last stage to eventually see the new data, effectively losing the old one.
    //   This is bad.
    // - Solution: We need a 'full' signal internally.
    //   'full' is high if the last stage has valid data.
    //   We only load new data if 'full' is low.
    //   But wait, if 'full' is low, it means the last stage is empty. Does that mean the whole chain is empty?
    //   Not necessarily.
    //   Let's reconsider the standard "Synchronizer" pattern.
    //   Usually, it's just a chain of flip-flops.
    //   If the producer is compliant (stops sending when dready_o is low), then a simple chain works.
    //   If the producer is not compliant, we need backpressure.
    //   Given the prompt "Bring each new input value into the local clock domain coherently", 
    //   it implies we should not lose data.
    //   So, we will implement a simple backpressure mechanism:
    //   - Track if the last stage has valid data.
    //   - If the last stage has valid data, we consider the buffer "full" for the purpose of accepting new data?
    //     No, that's incorrect. The buffer is full only when the last stage has data AND we cannot shift it out?
    //     Actually, in a shift register, you can always shift. The issue is overwriting the head before the tail is consumed.
    //     If we have a depth of N, we can hold N items.
    //     If the producer sends N items and then stops, we are fine.
    //     If the producer keeps sending while the consumer is slow, we lose data.
    //     To prevent this, we must stop accepting new data when the last stage has valid data.
    //     Why? Because if the last stage has valid data, it means the consumer hasn't taken it yet.
    //     If we overwrite the head, that data will eventually reach the tail and overwrite the current valid data.
    //     So, condition to load: dready_i AND NOT (last_stage_valid).
    
    reg [DWIDTH-1:0] last_stage_valid;
    
    // Always block for combinational logic to determine next state
    always @(*) begin
        // Initialize
        for (integer i = 0; i < STAGES; i = i + 1) begin
            data_reg[i] = '0;
            ready_reg[i] = 1'b0;
        end
        last_stage_valid = 1'b0;
        
        // Logic for the last stage validity
        // The last stage is valid if it has captured data in the past.
        // We can infer this from the ready signal of the last stage?
        // Actually, let's just track validity explicitly or use the ready_reg logic.
        // Let's use a separate validity flag for the last stage to drive the load enable.
        // Or simpler: The last stage is valid if ready_reg[STAGES-1] was ever set?
        // No, ready_reg[i] should indicate if data_reg[i] is valid.
        
        // Let's restructure:
        // ready_reg[i] = (data_reg[i] != '0) ? 1'b1 : 1'b0; 
        // But '0' is a valid data value. So we need an explicit valid flag.
        
        // Revised State:
        // valid_reg[i]: indicates if data_reg[i] contains valid data.
        
        // Let's rewrite the logic inside the always block or use a separate always block for combinational.
        // Since we are using non-blocking assignments for registers, we need combinational logic for next state.
        
        // Next state logic
        for (integer i = 0; i < STAGES; i = i + 1) begin
            if (i == 0) begin
                // Stage 0: Capture din if dready_i is high AND the chain is not "full".
                // Chain is "full" if the last stage has valid data.
                // We need to know if the last stage has valid data.
                // Let's assume we have a 'valid' flag for each stage.
                // But to keep it simple and efficient, we can just check the last stage's validity.
                // However, we need to calculate the next validity for the last stage to decide the load enable for stage 0.
                // This creates a dependency loop if we do it all in one combinational block without care.
                
                // Let's use a separate always block for the combinational logic to avoid loops.
            end
        end
    end

    // Let's use a single always_ff block for sequential logic and a combinational block for next state.
    
    // Combinational logic for next state
    always @(*) begin
        reg [DWIDTH-1:0] next_data [STAGES-1:0];
        reg next_valid [STAGES-1:0];
        
        // Determine validity of the last stage to check for backpressure
        // We need to know the current validity of the last stage to decide if we can load stage 0.
        // But we are calculating next states.
        // Let's assume the current validity is available in the registers.
        // We need to read the current validity of the last stage.
        // Since we are in a combinational block, we can read the current values of data_reg.
        // But data_reg is a reg array. In Verilog, reading a reg in a combinational block is fine.
        
        // Check if the last stage currently has valid data
        // We need a way to track validity. Let's assume data != '0' is not enough.
        // Let's add a 'valid' array.
        
        // Actually, let's simplify.
        // We will use the fact that if the last stage has valid data, we shouldn't overwrite the head.
        // How do we know if the last stage has valid data?
        // We can maintain a 'valid' flag for each stage.
        
        // Let's restart the design with explicit 'valid' flags.
        
        // ... (Logic will be implemented below in the final code block)
    end

    // Sequential Logic
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (integer i = 0; i < STAGES; i = i + 1) begin
                data_reg[i] <= '0;
                valid_reg[i] <= 1'b0;
            end
            dready_o <= 1'b0;
            dout <= '0;
        end else begin
            // Shift data forward
            for (integer i = 0; i < STAGES - 1; i = i + 1) begin
                data_reg[i+1] <= data_reg[i];
                valid_reg[i+1] <= valid_reg[i];
            end
            
            // Load into first stage
            // Condition: dready_i is high AND the last stage is NOT valid (to prevent overwriting)
            // Wait, if the last stage is valid, it means there is data in the pipeline.
            // If we load new data into stage 0, it will eventually reach stage STAGES-1 and overwrite the valid data.
            // So we only load if the last stage is NOT valid.
            // BUT, what if the chain is empty? Then last stage is not valid, we load.
            // What if the chain has data in stage 0 but not stage 1?
            // If we load, stage 0 gets new data, stage 1 gets old stage 0 data.
            // Eventually, the old data reaches the end.
            // The problem is only if the last stage is ALREADY valid.
            // If the last stage is valid, we must NOT load new data into stage 0.
            
            if (dready_i && !valid_reg[STAGES-1]) begin
                data_reg[0] <= din;
                valid_reg[0] <= 1'b1;
            end else begin
                data_reg[0] <= data_reg[0]; // Hold
                valid_reg[0] <= valid_reg[0]; // Hold
            end
            
            // Output logic
            if (valid_reg[STAGES-1]) begin
                dout <= data_reg[STAGES-1];
                dready_o <= 1'b1;
            end else begin
                dout <= '0;
                dready_o <= 1'b0;
            end
        end
    end

    // We need to declare valid_reg array
    reg valid_reg [STAGES-1:0];

endmodule

module data_sync #(
    parameter STAGES = 2,
    parameter DWIDTH = 8
)(
    input                  clk,
    input                  rstn,
    input  [DWIDTH-1:0]    din,
    input                  dready_i,
    output reg [DWIDTH-1:0] dout,
    output reg             dready_o
);

    // Arrays to store data and validity status for each stage
    reg [DWIDTH-1:0] data_reg [STAGES-1:0];
    reg              valid_reg [STAGES-1:0];

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            // Reset state
            for (integer i = 0; i < STAGES; i = i + 1) begin
                data_reg[i] <= '0;
                valid_reg[i] <= 1'b0;
            end
            dout <= '0;
            dready_o <= 1'b0;
        end else begin
            // Shift data and validity from stage i to i+1
            for (integer i = 0; i < STAGES - 1; i = i + 1) begin
                data_reg[i+1] <= data_reg[i];
                valid_reg[i+1] <= valid_reg[i];
            end

            // Load new data into the first stage
            // Only load if dready_i is asserted AND the last stage is not currently valid
            // This prevents overwriting data that hasn't been consumed yet (backpressure)
            if (dready_i && !valid_reg[STAGES-1]) begin
                data_reg[0] <= din;
                valid_reg[0] <= 1'b1;
            end else begin
                // Hold current data and validity in the first stage
                data_reg[0] <= data_reg[0];
                valid_reg[0] <= valid_reg[0];
            end

            // Drive output based on the last stage
            if (valid_reg[STAGES-1]) begin
                dout <= data_reg[STAGES-1];
                dready_o <= 1'b1;
            end else begin
                dout <= '0;
                dready_o <= 1'b0;
            end
        end
    end

endmodule
