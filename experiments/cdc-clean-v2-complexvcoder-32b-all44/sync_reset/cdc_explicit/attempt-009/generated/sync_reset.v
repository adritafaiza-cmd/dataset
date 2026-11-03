module sync_reset #
(
    parameter N = 2
)
(
    input  wire clk,
    input  wire rst,
    output wire out
);

    // Internal pipeline signal
    reg [N-1:0] sync_pipeline;

    always @(posedge clk) begin
        if (rst) begin
            sync_pipeline <= {N{1'b1}};
        end else begin
            sync_pipeline <= {sync_pipeline[N-2:0], 1'b0};
        end
    end

    // Output is the last stage of the pipeline
    assign out = sync_pipeline[N-1];

endmodule
