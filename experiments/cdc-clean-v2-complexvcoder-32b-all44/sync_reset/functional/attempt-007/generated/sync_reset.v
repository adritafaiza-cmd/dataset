module sync_reset #
(
    parameter N = 2
)
(
    input  wire clk,
    input  wire rst,
    output wire out
);

    // Internal pipeline register
    reg [N-1:0] sync_reg;

    // Synchronous reset and pipeline logic
    always @(posedge clk) begin
        if (rst) begin
            sync_reg <= {N{1'b1}};
        end else begin
            sync_reg <= {sync_reg[N-2:0], 1'b0};
        end
    end

    // Assign the output as the last stage of the pipeline
    assign out = sync_reg[N-1];

endmodule
