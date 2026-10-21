```verilog
`timescale 1ns / 1ps

module areset_sync #(
    parameter STAGES = 2
)(
    input  wire        clk,
    input  wire        async_rst_i,
    output reg         sync_rst_o
);

    // Internal state to track the number of clock cycles since async_rst_i went low
    reg [STAGES - 1 : 0] rst_count;

    // Synchronize the release of the asynchronous reset
    // We use a counter to ensure the reset is held for at least 'STAGES' clock cycles
    // after the asynchronous reset signal is de-asserted.
    
    always @(posedge clk) begin
        if (async_rst_i) begin
            // If async_rst_i is high, assert the synchronous reset immediately
            sync_rst_o <= 1'b1;
            rst_count <= 0;
        end else begin
            // If async_rst_i is low, we need to wait for STAGES clock cycles
            // before releasing the synchronous reset to ensure clean release.
            if (rst_count < STAGES) begin
                rst_count <= rst_count + 1'b1;
                sync_rst_o <= 1'b1;
            end else begin
                rst_count <= 0;
                sync_rst_o <= 1'b0;
            end
        end
    end

endmodule
```<|im_end|>
