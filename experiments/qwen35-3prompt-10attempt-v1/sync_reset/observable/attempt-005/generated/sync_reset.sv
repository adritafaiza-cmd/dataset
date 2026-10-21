```verilog
module sync_reset #
(
    parameter N = 2
)
(
    input  wire clk,
    input  wire rst,
    output wire out
);

    reg [N-1:0] counter;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
            out     <= 1'b1;
        end else begin
            counter <= counter + 1'b1;
            if (counter == N)
                out <= 1'b0;
            else
                out <= 1'b1;
        end
    end

endmodule
```<|im_end|>
