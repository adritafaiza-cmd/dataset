```verilog
`timescale 1ns / 1ps

module areset_sync #(
    parameter STAGES = 2
)(
    input  wire clk,
    input  wire async_rst_i,
    output wire sync_rst_o
);

    // Internal signal to hold the synchronized reset state
    reg sync_rst_int;

    // Generate the chain of flip-flops for synchronization
    // We use a non-blocking assignment within a generate loop
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : rst_sync_chain
            reg rst_stage;
            
            // First stage: Sample the asynchronous reset
            if (i == 0) begin : stage_0
                always @(posedge clk or posedge async_rst_i) begin
                    if (async_rst_i)
                        rst_stage <= 1'b1;
                    else
                        rst_stage <= 1'b0;
                end
            end
            // Subsequent stages: Chain the previous stage's output
            else begin : stage_n
                always @(posedge clk) begin
                    if (rst_stage)
                        rst_stage <= 1'b1;
                    else
                        rst_stage <= 1'b0;
                end
            end
            
            // Pass the signal to the next stage in the chain
            if (i < STAGES - 1)
                rst_stage <= rst_stage; // This line is logically redundant due to the always block above but ensures flow
            else
                sync_rst_int <= rst_stage;
        end
    endgenerate

    // Assign the final synchronized signal to the output
    assign sync_rst_o = sync_rst_int;

endmodule
```<|im_end|>
