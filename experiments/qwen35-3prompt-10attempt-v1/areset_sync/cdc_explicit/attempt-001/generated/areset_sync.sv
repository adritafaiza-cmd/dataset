module areset_sync #(
    parameter STAGES = 2
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    reg [STAGES-1:0] rst_pipe;

    // Synchronize the asynchronous reset release signal
    // The reset is asserted immediately on async_rst_i.
    // The release (de-assertion) is synchronized through STAGES flip-flops.
    // This ensures that sync_rst_o only de-asserts after being stable for STAGES clock cycles,
    // preventing metastability and ensuring safe reset release in the destination domain.
    always @(posedge clk or posedge async_rst_i) begin
        if (async_rst_i)
            rst_pipe <= {STAGES{1'b1}};
        else
            rst_pipe <= {rst_pipe[STAGES-2:0], 1'b1};
    end

    // Invert the synchronized pipeline to generate the active-low reset output
    // When rst_pipe is all 1s, the reset is active.
    assign sync_rst_o = rst_pipe[STAGES-1];

endmodule<|im_end|>
