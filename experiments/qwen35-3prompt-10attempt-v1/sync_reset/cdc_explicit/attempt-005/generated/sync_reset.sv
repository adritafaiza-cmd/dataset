module sync_reset #
(
    parameter N = 2
)
(
    input  wire clk,
    input  wire rst,
    output wire out
);

    reg [N-1:0] state;

    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= 0;
        else
            state <= state + 1;
    end

    assign out = (state == N);

endmodule<|im_end|>
