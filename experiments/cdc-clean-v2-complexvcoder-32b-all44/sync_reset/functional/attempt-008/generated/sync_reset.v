module sync_reset #
(
    parameter N = 2
)
(
    input  wire clk,
    input  wire rst,
    output wire out
);

    // Internal signal to hold the synchronized reset
    reg [N-1:0] sync_chain;

    // Synchronize the reset signal using a pipeline of flip-flops
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sync_chain <= {N{1'b1}};
        end else begin
            sync_chain <= {sync_chain[N-2:0], 1'b0};
        end
    end

    // Assign the last stage of the pipeline to the output
    assign out = sync_chain[N-1];

endmodule
