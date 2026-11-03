module sync_reset #
(
    parameter N = 2
)
(
    input  wire clk,
    input  wire rst,
    output wire out
);

    reg [N-1:0] sync_stages;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sync_stages <= {N{1'b1}};
        end else begin
            sync_stages <= {sync_stages[N-2:0], 1'b0};
        end
    end

    assign out = sync_stages[N-1];

endmodule
