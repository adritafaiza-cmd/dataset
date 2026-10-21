```verilog
`timescale 1ns/1ps

module areset_sync #(
    parameter STAGES = 2
)(
    input  wire        clk,
    input  wire        async_rst_i,
    output reg         sync_rst_o
);

    // Internal state to track the release of the asynchronous reset
    // We use a counter that increments on the active clock edge
    // while the async reset is asserted. Once the counter reaches
    // the configured depth, we know the reset has been stable
    // for enough cycles to be safely released.
    
    reg [STAGES-1:0] release_cnt;
    
    // Synchronize the async reset signal to detect its assertion
    // and track the number of cycles it has been active.
    reg sync_rst_detect;
    
    // Logic to detect when the async reset is currently asserted
    // This is a simple synchronous check against the current clock cycle
    // to avoid metastability issues from the async signal itself.
    // We assume async_rst_i is the source of truth for assertion.
    
    // Counter logic:
    // If async_rst_i is high, we increment the counter.
    // If async_rst_i is low, we stop incrementing.
    // Once the counter equals STAGES, we assert the output reset.
    // However, the requirement is to "assert promptly" but "release cleanly".
    // 
    // Strategy:
    // 1. Detect the rising edge of async_rst_i to assert sync_rst_o immediately.
    // 2. Count the number of clock cycles async_rst_i remains high.
    // 3. When the count reaches STAGES, assert sync_rst_o.
    // 4. When async_rst_i goes low, start counting down from STAGES.
    // 5. When the count reaches 0, de-assert sync_rst_o.
    
    // Edge detection for async_rst_i
    reg async_rst_prev;
    
    always @(posedge clk) begin
        // Detect rising edge of async reset
        if (async_rst_i && !async_rst_prev) begin
            // Assert reset immediately upon detection
            sync_rst_o <= 1'b1;
        end
        
        // Update previous state
        async_rst_prev <= async_rst_i;
        
        // Counter logic based on async_rst_i state
        if (sync_rst_o) begin
            if (async_rst_i) begin
                // Reset is still asserted, increment counter
                if (release_cnt < STAGES) begin
                    release_cnt <= release_cnt + 1'b1;
                end
            end else begin
                // Reset has been de-asserted, start counting down
                if (release_cnt > 0) begin
                    release_cnt <= release_cnt - 1'b1;
                end
            end
        end
    end

    // Final release logic:
    // If the counter has reached STAGES, it means the async reset was stable
    // for the required number of cycles. We can now safely de-assert the sync reset.
    always @(posedge clk) begin
        if (release_cnt >= STAGES) begin
            sync_rst_o <= 1'b0;
        end
    end

endmodule
```<|im_end|>
