module sync_reset #
(
    parameter N = 2
)
(
    input  wire clk,
    input  wire rst,
    output wire out
);

reg [N-1:0] rst_sync;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        rst_sync <= {N{1'b1}};
    end else begin
        rst_sync <= {rst_sync[N-2:0], 1'b0};
    end
end

assign out = rst_sync[N-1];

endmodule
