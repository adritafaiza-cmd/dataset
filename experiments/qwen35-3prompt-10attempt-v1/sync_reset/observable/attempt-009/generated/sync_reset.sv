```verilog
module sync_reset #(
    parameter N = 2
)(
    input  wire clk,
    input  wire rst,
    output wire out
);

    reg [N-1:0] counter;

    always @(posedge clk or posedge rst) begin
        if (rst)
            counter <= 0;
        else
            counter <= counter + 1;
    end

    assign out = (counter == N);

endmodule
```<|im_end|>
