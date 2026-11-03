module sync_reset #
(
    parameter N = 2
)
(
    input  wire clk,
    input  wire rst,
    output wire out
);

    // Internal signal to hold the synchronization stages
    reg [N-1:0] sync_stage;

    // Synchronize the reset signal through a pipeline of N registers
    always @(posedge clk) begin
        sync_stage[0] <= rst;
        for (integer i = 1; i < N; i = i + 1) begin
            sync_stage[i] <= sync_stage[i-1];
        end
    end

    // The output is the last stage of the synchronization pipeline
    assign out = sync_stage[N-1];

endmodule
