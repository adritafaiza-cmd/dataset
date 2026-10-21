module areset_sync #(
    parameter STAGES = 2
)(
    input  wire clk,
    input  wire async_rst_i,
    output wire sync_rst_o
);

    // Internal state registers for the release synchronizer
    // Using STAGES flip-flops to safely de-assert the reset signal
    reg [STAGES-1:0] rst_pipe;

    // Synchronous logic to propagate the reset release
    // The reset is asserted immediately on async_rst_i
    // The reset is de-asserted only after passing through the pipeline stages
    always @(posedge clk or posedge async_rst_i) begin
        if (async_rst_i) begin
            rst_pipe <= {STAGES{1'b1}};
        end else begin
            rst_pipe <= {rst_pipe[STAGES-2:0], 1'b1};
        end
    end

    // Output is the inverse of the pipeline state
    // When all stages are 1, the reset is active
    assign sync_rst_o = rst_pipe[STAGES-1];

endmodule<|im_end|>
