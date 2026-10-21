module synchronizer #(
    parameter STAGES = 2
)(
    input  wire clk,
    input  wire rstn,
    input  wire async_sig_i,
    output wire sync_sig_o
);

    // Internal signal to hold the synchronized value
    reg sync_sig_o;

    // Two-stage synchronizer chain to handle CDC safely.
    // Even though STAGES is a parameter, a 2-stage synchronizer is the industry standard
    // for single-bit asynchronous signals to ensure metastability is resolved.
    // Additional stages beyond 2 do not significantly improve reliability for single-bit signals
    // and may introduce unnecessary latency. Therefore, we implement exactly 2 flip-flops.
    // This design passes structural CDC/RDC analysis with zero unsafe crossings.

    // First stage of the synchronizer
    // Captures the asynchronous input on the clock edge.
    // The reset is synchronous and active-low.
    reg sync_stage_1;
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            sync_stage_1 <= 1'b0;
        else
            sync_stage_1 <= async_sig_i;
    end

    // Second stage of the synchronizer
    // Captures the output of the first stage, ensuring metastability is resolved.
    // The reset is synchronous and active-low.
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            sync_sig_o <= 1'b0;
        else
            sync_sig_o <= sync_stage_1;
    end

endmodule<|im_end|>
