module sync_reset #(
    parameter N = 2
) (
    input clk,
    input rst,
    output out
);

reg [N-1:0] sync;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        sync <= {N{1'b1}};
    end else begin
        sync <= {sync[N-2:0], 1'b0};
    end
end

assign out = sync[N-1];

endmodule
