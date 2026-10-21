module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Synchronization logic for the reset signal
    // When test_mode_i is high, the reset is passed through directly (bypassed).
    // Otherwise, a 2-stage synchronizer is used to ensure metastability-free release.
    logic rst_sync_1, rst_sync_2;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_sync_1 <= 1'b0;
            rst_sync_2 <= 1'b0;
        end else begin
            rst_sync_1 <= rst_ni;
            rst_sync_2 <= rst_sync_1;
        end
    end

    // Generate the synchronized active-low reset output
    // If test_mode_i is high, rst_no follows rst_ni directly.
    // Otherwise, rst_no follows the synchronized signal rst_sync_2.
    assign rst_no = test_mode_i ? rst_ni : rst_sync_2;

    // Generate the initialization qualifier
    // init_no is asserted (0) for one clock cycle after the reset is released.
    // It is de-asserted (1) once the reset is stable.
    // In test mode, it follows the same logic as rst_no but delayed by one cycle relative to the bypassed reset.
    logic rst_sync_3;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_sync_3 <= 1'b0;
        end else begin
            rst_sync_3 <= rst_sync_2;
        end
    end

    // init_no is 0 (active) when the reset has just been released (rst_sync_2 went from 0 to 1)
    // and 1 (inactive) otherwise.
    // We use a simple state check: if rst_sync_2 is high, we are out of reset.
    // We need to assert init_no low for exactly one cycle after rst_no becomes high.
    // Since rst_no is the output, we can derive init_no based on the transition of rst_sync_2.
    
    // Alternative approach for init_no:
    // Assert init_no low when rst_sync_2 is 1 AND the previous cycle was 0.
    // However, a simpler synchronous approach often used is:
    // init_no = ~rst_sync_2 | (rst_sync_2 & ~rst_sync_3); 
    // But let's stick to a clear state machine or edge detection logic.
    
    // Let's use a dedicated flip-flop to detect the release edge.
    logic rst_released;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_released <= 1'b0;
        end else begin
            rst_released <= rst_sync_2;
        end
    end

    // init_no is active low (0) for one cycle after reset release.
    // It is 1 when rst_released is 0 (during reset) or when rst_released is 1 and the previous state was 0.
    // Actually, the requirement says "short initialization qualifier after reset release".
    // Usually, this means: Reset -> Release -> Init Pulse -> Normal.
    // So init_no should be 0 during reset, 0 for 1 cycle after release, and 1 thereafter.
    
    // Logic:
    // If rst_ni is low, init_no = 1 (inactive) - Wait, usually init is active during reset too?
    // Re-reading: "init_no is a short initialization qualifier after reset release."
    // Standard behavior: 
    // 1. Reset Active: init_no = 1 (inactive) or 0 (active)? 
    //    Typically, "qualifier" implies it enables initialization logic. 
    //    If it's active-low (implied by naming convention matching rst_no), then:
    //    - During reset: init_no = 1 (inactive)
    //    - One cycle after reset: init_no = 0 (active)
    //    - After that: init_no = 1 (inactive)
    
    // Let's implement: init_no = 0 only when rst_released is 1 AND the previous rst_released was 0.
    // Otherwise init_no = 1.
    
    // To do this synchronously:
    // We need to know if we just came out of reset.
    // Let's use a counter or a single bit to track the "just released" state.
    
    logic init_pulse;
    
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            init_pulse <= 1'b0;
        end else begin
            // If we are out of reset now, but were in reset before, then pulse.
            if (rst_sync_2 && !rst_released) begin
                init_pulse <= 1'b1;
            end else begin
                init_pulse <= 1'b0;
            end
        end
    end

    // Note: The variable 'rst_released' inside the block above is a local variable in the procedural block?
    // No, I declared 'rst_released' as a logic variable.
    // Wait, the logic inside the always block for 'rst_released' updates 'rst_released' at the same time as 'init_pulse'.
    // This creates a dependency issue if not careful.
    // 'rst_released' is updated at posedge clk_i.
    // 'init_pulse' logic uses 'rst_released' (current value) and 'rst_sync_2' (current value).
    // If rst_ni is low, rst_released becomes 0.
    // If rst_ni is high:
    //   rst_released <= rst_sync_2.
    //   init_pulse <= (rst_sync_2 && !rst_released).
    // This works because 'rst_released' on the RHS is the value from the previous cycle (non-blocking assignment semantics).
    
    assign init_no = ~init_pulse;

endmodule<|im_end|>
