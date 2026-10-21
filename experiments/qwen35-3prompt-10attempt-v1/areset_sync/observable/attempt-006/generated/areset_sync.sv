```verilog
`timescale 1ns / 1ps

module areset_sync #(
    parameter STAGES = 2
)(
    input  wire clk,
    input  wire async_rst_i,
    output wire sync_rst_o
);

    reg [STAGES-1:0] sync_rst_reg;

    // Synchronize the asynchronous reset release signal
    // We use a counter-like approach where we count down from STAGES
    // when the async reset is deasserted to ensure clean release.
    // However, a more robust method for "prompt assert, clean release" 
    // with a specific depth is to use a chain of flip-flops for the 
    // deassertion event, then drive the output based on the state of that chain.
    
    // Strategy:
    // 1. Detect the transition of async_rst_i from 1 to 0 (release).
    // 2. Count down STAGES times on the destination clock.
    // 3. While counting, keep sync_rst_o asserted.
    // 4. Once count reaches 0, deassert sync_rst_o.
    // 5. If async_rst_i goes high again before the count finishes, 
    //    the logic must handle it. The simplest robust way for a generic 
    //    synchronizer with depth is often a chain of flip-flops for the 
    //    "released" state, but to strictly meet "prompt assert" and "clean release with depth",
    //    we implement a counter that resets if the input goes high again.
    
    // Let's use a counter approach:
    // - If async_rst_i is high, sync_rst_o is high.
    // - If async_rst_i goes low, we start a countdown.
    // - During countdown, sync_rst_o remains high.
    // - When countdown hits 0, sync_rst_o goes low.
    // - If async_rst_i goes high during countdown, we must reset the countdown 
    //   immediately to ensure "prompt" re-assertion, but we must ensure we don't 
    //   glitch the output.
    
    // Actually, the standard robust pattern for "clean release" with depth N is:
    // Use N flip-flops to synchronize the 'release' edge.
    // But the requirement "prompt assert" implies if the async signal toggles 
    // frequently, we want to follow it closely once synchronized.
    
    // Implementation Plan:
    // 1. Create a chain of STAGES flip-flops to detect the release edge reliably.
    //    Let's call the last stage 'rst_released'.
    // 2. However, simply synchronizing the edge might not be enough if the 
    //    async signal stays low for a long time; we need to hold the reset.
    //    
    // Refined Plan for "Prompt Assert, Clean Release":
    // We will use a counter that counts down from STAGES when the synchronized 
    // release signal is active.
    // 
    // Step 1: Synchronize the 'release' event (1->0 transition of async_rst_i).
    // We can do this by detecting the edge in the destination clock domain.
    // But a simpler and more common industrial approach for this specific 
    // requirement (reset release synchronizer) is:
    // - Assert sync_rst_o immediately if async_rst_i is high.
    // - If async_rst_i goes low, we wait for STAGES cycles before deasserting sync_rst_o.
    // - If async_rst_i goes high again during the wait, we reset the wait counter 
    //   immediately (prompt re-assertion logic).
    
    // Let's implement a counter based approach:
    // counter: STAGES-1 down to 0.
    // If async_rst_i == 1, sync_rst_o = 1.
    // If async_rst_i == 0:
    //    If counter == 0, sync_rst_o = 0.
    //    Else, decrement counter.
    //    BUT, we must ensure the counter doesn't glitch if async_rst_i toggles.
    //    We need to synchronize the 'async_rst_i' signal first to avoid metastability 
    //    affecting the counter logic, OR use a robust edge detection.
    
    // Best Practice for this specific module:
    // 1. Synchronize async_rst_i to get a clean 'rst_sync' signal.
    // 2. Use a counter that counts down from STAGES when rst_sync is low.
    // 3. If rst_sync goes high, reset the counter to STAGES (or keep it high).
    //    Wait, if we just sync the signal, a single glitch in async_rst_i could 
    //    cause the counter to start counting down erroneously.
    //    
    // Alternative Robust Design:
    // Use a chain of flip-flops to detect the release, then use a counter.
    // However, the most standard and safe implementation for "Reset Release Synchronizer"
    // with depth N is:
    // - Detect the 1->0 transition of async_rst_i.
    // - Count N cycles.
    // - Deassert after N cycles.
    // - If 1->0 happens again before N cycles, restart the count.
    
    // Let's go with the Counter approach with synchronized input to prevent metastability 
    // from affecting the counter logic directly, assuming the input is sampled correctly.
    // To be extra safe against metastability on the control path, we can use a 
    // 2-stage synchronizer on the 'release' condition itself, but since the requirement 
    // is about the depth of the release, a counter driven by the synchronized signal 
    // is the standard solution.
    
    // We will use a 2-stage synchronizer on async_rst_i to create 'rst_sync'.
    // Then we use a counter.
    
    reg rst_sync;
    reg [STAGES-1:0] cnt;

    // Synchronize async_rst_i
    // Stage 1
    reg rst_sync_1;
    always @(posedge clk) begin
        rst_sync_1 <= async_rst_i;
    end
    // Stage 2
    always @(posedge clk) begin
        rst_sync <= rst_sync_1;
    end

    // Counter logic
    // If rst_sync is high, we are in reset.
    // If rst_sync is low, we count down.
    // If cnt reaches 0, we release reset.
    // If rst_sync goes high while counting, we must reset the counter to ensure 
    // the next release is handled correctly? 
    // Actually, if rst_sync goes high, we want sync_rst_o to go high immediately.
    // So if rst_sync is high, cnt should be irrelevant, but we can just set cnt to STAGES 
    // or a value that keeps sync_rst_o high.
    // Logic: 
    // If rst_sync == 1, sync_rst_o = 1.
    // If rst_sync == 0:
    //    If cnt == 0, sync_rst_o = 0.
    //    Else, cnt = cnt - 1.
    //    sync_rst_o = 1.
    
    // Wait, there is a race condition if rst_sync changes from 0 to 1 while cnt > 0.
    // If rst_sync becomes 1, we want sync_rst_o to become 1 immediately.
    // The logic above handles that: if rst_sync is 1, sync_rst_o is 1.
    // But we need to make sure cnt doesn't continue counting down if rst_sync is 1.
    
    always @(posedge clk) begin
        if (rst_sync) begin
            cnt <= STAGES; // Reset counter to max value to keep output high
        end else begin
            if (cnt == 0) begin
                cnt <= STAGES; // Should not happen if logic is correct, but for safety
            end else begin
                cnt <= cnt - 1;
            end
        end
    end
    
    // Output logic
    assign sync_rst_o = (rst_sync) ? 1'b1 : (cnt == 0) ? 1'b0 : 1'b1;
    
    // Simplified output logic:
    // If rst_sync is high, output is high.
    // If rst_sync is low, output is high if cnt > 0, else low.
    // This can be written as:
    // sync_rst_o = rst_sync | (cnt != 0);
    
    assign sync_rst_o = rst_sync | (cnt != 0);

endmodule
```<|im_end|>
