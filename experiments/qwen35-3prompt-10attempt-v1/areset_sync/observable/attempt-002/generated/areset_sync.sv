```verilog
`timescale 1ns/1ps

module areset_sync #(
    parameter STAGES = 2
)(
    input  wire        clk,
    input  wire        async_rst_i,
    output reg         sync_rst_o
);

    // Internal state to track the number of clock cycles since async_rst_i was released
    reg [STAGES-1:0] release_count;
    reg [STAGES-1:0] release_count_next;

    // Logic to detect when async_rst_i transitions from high to low
    // We use a simple edge detector on the async_rst_i signal
    reg async_rst_i_prev;
    reg async_rst_i_edge;

    always @(posedge clk) begin
        async_rst_i_prev <= async_rst_i;
        
        // Detect falling edge of async_rst_i (release event)
        async_rst_i_edge <= (async_rst_i == 1'b0) && (async_rst_i_prev == 1'b1);
    end

    // Synchronous counter logic
    always @(posedge clk) begin
        if (async_rst_i) begin
            // While async_rst_i is asserted, reset the counter and output
            release_count_next <= 0;
            sync_rst_o <= 1'b1;
        end
        else if (async_rst_i_edge) begin
            // On the first clock cycle after release, start counting
            release_count_next <= 1;
            sync_rst_o <= 1'b0;
        end
        else begin
            // Increment counter normally
            release_count_next <= release_count + 1;
            sync_rst_o <= 1'b0;
        end
    end

    // Output the final synchronized reset signal
    always @(posedge clk) begin
        release_count <= release_count_next;
    end

    // Final output assignment based on counter value
    // If counter is less than STAGES, keep reset low (clean release)
    // Once counter reaches STAGES, we can safely deassert reset
    always @(posedge clk) begin
        if (release_count < STAGES) begin
            sync_rst_o <= 1'b0;
        end
        else begin
            sync_rst_o <= 1'b0;
        end
    end

    // Note: The logic above can be simplified. Let's refactor for clarity and correctness.
    // The requirement is: assert promptly, release cleanly with destination clock respecting depth.
    // "Assert promptly" means sync_rst_o should go high immediately when async_rst_i goes high.
    // "Release cleanly" means sync_rst_o should stay low for STAGES cycles after async_rst_i goes low.
    
    // Revised approach:
    // 1. Detect async_rst_i going high -> set sync_rst_o high immediately.
    // 2. Detect async_rst_i going low -> start a counter.
    // 3. While counter < STAGES, keep sync_rst_o low.
    // 4. Once counter >= STAGES, sync_rst_o can be low (already low).
    
    // Actually, the standard pattern is:
    // - When async_rst_i is high, sync_rst_o is high.
    // - When async_rst_i goes low, we wait STAGES cycles before allowing sync_rst_o to go low? 
    //   No, that's not right. The reset should be asserted when async_rst_i is asserted.
    //   The "release cleanly" means we must hold the reset low for STAGES cycles AFTER async_rst_i is released
    //   to ensure the domain is stable before deasserting the reset.
    
    // Correct interpretation:
    // - If async_rst_i is high, sync_rst_o must be high.
    // - If async_rst_i goes low, sync_rst_o must remain low for at least STAGES clock cycles.
    // - After STAGES cycles, sync_rst_o can be deasserted (go low).
    
    // However, the typical use case for a reset synchronizer is:
    // - async_rst_i is an asynchronous reset that might be glitchy or not aligned.
    // - We want sync_rst_o to be a clean, synchronous reset in the clk domain.
    // - "Assert promptly": sync_rst_o goes high as soon as async_rst_i goes high.
    // - "Release cleanly": sync_rst_o stays high for at least one clock cycle, then goes low.
    //   But the "depth" parameter suggests we need to hold the reset low for STAGES cycles after async_rst_i is released?
    //   Actually, the common requirement is: hold the reset high for STAGES cycles after async_rst_i is released?
    //   No, that doesn't make sense. Let me re-read the requirement.
    
    // "Make reset assert promptly but release cleanly with the destination clock, respecting the configured depth."
    // This usually means:
    // - Assert: sync_rst_o = async_rst_i (but synchronized).
    // - Release: After async_rst_i goes low, we wait STAGES cycles before deasserting sync_rst_o?
    //   No, that would mean sync_rst_o stays high longer than async_rst_i.
    //   Actually, the typical requirement is:
    //   - When async_rst_i goes high, sync_rst_o goes high immediately.
    //   - When async_rst_i goes low, sync_rst_o stays high for STAGES cycles, then goes low.
    //   This ensures that the reset is held for a minimum duration in the destination domain.
    
    // But wait, the standard reset synchronizer for release is:
    // - Detect async_rst_i going low.
    // - Count STAGES cycles.
    // - After STAGES cycles, allow sync_rst_o to go low.
    // This means sync_rst_o is high for at least STAGES cycles after async_rst_i goes low.
    
    // Let's implement this correctly:
    
    reg [STAGES-1:0] count;
    reg async_rst_i_edge_neg; // Falling edge of async_rst_i
    
    always @(posedge clk) begin
        if (async_rst_i) begin
            // Assert reset immediately
            sync_rst_o <= 1'b1;
            count <= 0;
        end
        else begin
            // async_rst_i is low
            if (async_rst_i_edge_neg) begin
                // Falling edge detected, start counting
                count <= 1;
            end
            else begin
                // Increment counter
                count <= count + 1;
            end
            // Deassert reset only after STAGES cycles
            if (count >= STAGES) begin
                sync_rst_o <= 1'b0;
            end
            else begin
                sync_rst_o <= 1'b1;
            end
        end
    end

    // Detect falling edge of async_rst_i
    always @(posedge clk) begin
        if (async_rst_i == 1'b0 && async_rst_i_edge_neg == 1'b0) begin
            // This is not the right way. Let's use a separate register.
        end
    end

    // Better approach for edge detection:
    reg async_rst_i_prev;
    always @(posedge clk) begin
        async_rst_i_prev <= async_rst_i;
    end

    // Combine everything in one always block for simplicity and correctness
    always @(posedge clk) begin
        if (async_rst_i) begin
            // Assert reset
            sync_rst_o <= 1'b1;
            count <= 0;
        end
        else begin
            // async_rst_i is low
            if (async_rst_i_prev == 1'b1) begin
                // Falling edge detected
                count <= 1;
            end
            else begin
                // Increment counter
                count <= count + 1;
            end
            
            // Deassert reset only after STAGES cycles
            if (count >= STAGES) begin
                sync_rst_o <= 1'b0;
            end
            else begin
                sync_rst_o <= 1'b1;
            end
        end
    end

endmodule
```<|im_end|>
