```verilog
module areset_sync #(
    parameter STAGES = 2
)(
    input  wire clk,
    input  wire async_rst_i,
    output wire sync_rst_o
);

    reg [STAGES-1:0] sync_reg;

    always @(posedge clk or posedge async_rst_i) begin
        if (async_rst_i)
            sync_reg <= 0;
        else
            sync_reg <= sync_reg + 1'b1;
    end

    assign sync_rst_o = (sync_reg < STAGES);

endmodule
```<|im_end|>
