module sync_reset #
(
    parameter N = 2
)
(
    input  wire clk,
    input  wire rst,
    output wire out
);

    reg [N-1:0] sync_reg;

    always @(posedge clk or posedge rst) begin
        if (rst)
            sync_reg <= {N{1'b0}};
        else
            sync_reg <= sync_reg + 1'b1;
    end

    assign out = (sync_reg == {N{1'b1}});

endmodule<|im_end|>
