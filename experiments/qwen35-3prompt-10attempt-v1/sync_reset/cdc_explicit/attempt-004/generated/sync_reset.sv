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
    reg out_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 0;
            out_reg <= 0;
        end else begin
            state <= state + 1;
            if (state == N) begin
                out_reg <= 1;
            end else begin
                out_reg <= 0;
            end
        end
    end

    assign out = out_reg;

endmodule<|im_end|>
