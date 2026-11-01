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

    always @(posedge clk) begin
        sync_reg <= {sync_reg[N-2:0], rst};
    end

    assign out = sync_reg[N-1];

endmodule
