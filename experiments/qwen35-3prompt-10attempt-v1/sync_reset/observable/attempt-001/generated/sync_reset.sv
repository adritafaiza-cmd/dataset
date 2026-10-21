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
    reg out_reg;

    // Synchronize the active-high reset signal to the destination clock domain
    // by counting N clock cycles after the reset is asserted.
    always @(posedge clk) begin
        if (rst) begin
            counter <= 0;
            out_reg <= 1'b1;
        end
        else begin
            counter <= counter + 1'b1;
            if (counter >= N) begin
                out_reg <= 1'b0;
            end
        end
    end

    assign out = out_reg;

endmodule
```<|im_end|>
