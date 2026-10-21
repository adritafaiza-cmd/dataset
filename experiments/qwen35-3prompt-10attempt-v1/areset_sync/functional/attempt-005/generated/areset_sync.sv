```verilog
module areset_sync #(
    parameter STAGES = 2
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    reg [STAGES-1:0] rst_pipe;

    always @(posedge clk) begin
        rst_pipe[0] <= async_rst_i;
        for (integer i = 1; i < STAGES; i = i + 1) begin
            rst_pipe[i] <= rst_pipe[i-1];
        end
    end

    assign sync_rst_o = rst_pipe[STAGES-1];

endmodule
```<|im_end|>
