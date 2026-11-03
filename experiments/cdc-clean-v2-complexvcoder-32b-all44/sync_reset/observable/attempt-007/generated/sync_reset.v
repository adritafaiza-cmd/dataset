module sync_reset #
(
    parameter N = 2
)
(
    input  wire clk,
    input  wire rst,
    output wire out
);

reg [N-1:0] sync_ff;

always @(posedge clk) begin
    if (rst) begin
        sync_ff <= {N{1'b1}};
    end else begin
        sync_ff <= {sync_ff[N-2:0], 1'b0};
    end
end

assign out = sync_ff[N-1];

endmodule
