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

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
            out_reg <= 1'b1;
        end else begin
            counter <= counter + 1'b1;
            if (counter >= N) begin
                out_reg <= 1'b0;
            end
        end
    end

    assign out = out_reg;

endmodule<|im_end|>
