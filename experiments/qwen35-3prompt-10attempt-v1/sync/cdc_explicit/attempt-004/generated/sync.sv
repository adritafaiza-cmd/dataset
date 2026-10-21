module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    // Internal clock for the destination domain (same as clk_i)
    // We use a single flip-flop chain for single-bit data.
    // For multi-bit data, we would need a multi-stage synchronizer per bit
    // or a dedicated multi-bit synchronizer module, but here we only have
    // a single-bit input 'serial_i'.
    
    // Generate a chain of flip-flops to synchronize the asynchronous signal.
    // The first stage captures the input on the destination clock.
    // Subsequent stages ensure metastability resolution.
    
    logic [STAGES-1:0] sync_chain;

    // First stage: Capture the asynchronous input
    // Note: In a true single-bit synchronizer, we often use two stages.
    // If STAGES is 1, we still need at least 2 stages for safety in most CDC checks,
    // but the parameter allows STAGES=1. To be safe and standard, we will ensure
    // the logic handles the chain correctly regardless of STAGES value.
    // However, strictly following the parameter:
    
    // We will instantiate a chain of D flip-flops.
    // To handle the reset safely across domains, we apply the reset to all stages.
    // Since rst_ni is active-low and asynchronous, we apply it directly to all FFs.
    
    // First stage
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            sync_chain[0] <= ResetValue;
        else
            sync_chain[0] <= serial_i;
    end

    // Subsequent stages
    genvar i;
    generate
        for (i = 1; i < STAGES; i = i + 1) begin : stage_gen
            always_ff @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni)
                    sync_chain[i] <= ResetValue;
                else
                    sync_chain[i] <= sync_chain[i-1];
            end
        end
    endgenerate

    // Output is the last stage of the synchronizer chain
    assign serial_o = sync_chain[STAGES-1];

endmodule<|im_end|>
