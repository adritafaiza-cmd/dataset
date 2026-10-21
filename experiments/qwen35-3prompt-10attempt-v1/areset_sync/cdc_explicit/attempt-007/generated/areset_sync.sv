module areset_sync #(
    parameter STAGES = 2
)(
    input  wire clk,
    input  wire async_rst_i,
    output wire sync_rst_o
);

    // Internal state registers for the release synchronizer
    // Using non-blocking assignments for sequential logic
    reg [STAGES-1:0] rst_pipe;

    // Synchronize the asynchronous reset release signal
    // The signal is captured on the first stage and then shifted through the pipeline
    // This ensures the reset de-assertion is safely synchronized to the clock domain
    always @(posedge clk or posedge async_rst_i) begin
        if (async_rst_i) begin
            rst_pipe <= {STAGES{1'b0}};
        end else begin
            rst_pipe <= {rst_pipe[STAGES-2:0], 1'b0};
        end
    end

    // The final output is the last bit of the pipeline
    // This represents the synchronized reset release signal
    assign sync_rst_o = rst_pipe[STAGES-1];

endmodule<|im_end|>
