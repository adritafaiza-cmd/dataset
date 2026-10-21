```verilog
module areset_sync #(
    parameter STAGES = 2
)(
    input  wire clk,
    input  wire async_rst_i,
    output wire sync_rst_o
);

    // Internal signal to hold the synchronized reset state
    // This signal will be driven by the pipeline stages
    reg sync_rst_int;

    // Pipeline stages for reset release synchronization
    // We use a chain of flip-flops to synchronize the reset de-assertion
    // across the clock domain boundary.
    // 
    // Architecture:
    // 1. First stage captures the reset release event on the destination clock.
    //    Since async_rst_i is active-high, we capture when it goes low.
    //    However, to ensure robustness against metastability during the transition,
    //    we typically synchronize the 'release' event.
    // 
    // 2. Subsequent stages (STAGES - 1) simply propagate the signal to ensure
    //    the release is stable and settled before being used by downstream logic.
    //
    // Note: The reset is asserted immediately by the input. The synchronization
    // only applies to the release (de-assertion) to prevent glitches from propagating
    // into the destination domain when the reset is removed.

    // Stage 0: Capture the reset release event.
    // We use a simple flip-flop chain. The first stage captures the state of async_rst_i.
    // Since async_rst_i is active high, when it goes low, the next stage will see a '0'.
    // To ensure the release is synchronized, we can either:
    // A) Synchronize the active high signal directly (standard approach).
    // B) Detect the falling edge and synchronize that.
    //
    // Standard approach for reset release:
    // The reset is asserted immediately. The release must be synchronized.
    // We create a pipeline where the first stage captures the async_rst_i value.
    // If async_rst_i is 1 (reset active), the output is 1.
    // If async_rst_i transitions to 0, the pipeline will eventually reflect this 0.
    // The depth ensures the transition is safely captured.

    reg [STAGES-1:0] rst_pipe;

    // Initialize the pipeline register array
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : rst_pipeline
            if (i == 0) begin
                // First stage: Capture the asynchronous reset signal
                // Using non-blocking assignment for sequential logic
                always @(posedge clk or posedge async_rst_i) begin
                    if (posedge async_rst_i) begin
                        // Reset is asserted
                        rst_pipe[i] <= 1'b1;
                    end else begin
                        // Reset is de-asserted, capture the 0 on the next clock edge
                        // Note: We rely on the clock edge to capture the release.
                        // If async_rst_i goes low, it will be sampled as 0 on the next rising edge of clk.
                        rst_pipe[i] <= 1'b0;
                    end
                end
            end else begin
                // Subsequent stages: Propagate the signal
                always @(posedge clk or posedge rst_pipe[i-1]) begin
                    if (posedge rst_pipe[i-1]) begin
                        rst_pipe[i] <= 1'b1;
                    end else begin
                        rst_pipe[i] <= 1'b0;
                    end
                end
            end
        end
    endgenerate

    // Output is the last stage of the pipeline
    assign sync_rst_o = rst_pipe[STAGES-1];

endmodule
```<|im_end|>
