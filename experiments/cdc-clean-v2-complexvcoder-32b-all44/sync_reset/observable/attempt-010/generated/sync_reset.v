module sync_reset #
(
    parameter N = 2
)
(
    input  wire clk,
    input  wire rst,
    output wire out
);

reg synced_rst;
reg [N-1:0] sync_pipeline;

// First DFF to synchronize the reset signal
dff dff1 (
    .clk(clk),
    .d(rst),
    .q(synced_rst)
);

// Pipeline of DFFs to further synchronize the reset signal
genvar i;
generate
    for (i = 0; i < N; i = i + 1) begin : sync_pipeline_gen
        if (i == 0) begin
            dff dff_sync (
                .clk(clk),
                .d(synced_rst),
                .q(sync_pipeline[i])
            );
        end else begin
            dff dff_sync (
                .clk(clk),
                .d(sync_pipeline[i-1]),
                .q(sync_pipeline[i])
            );
        end
    end
endgenerate

// Assign the final synchronized output
assign out = sync_pipeline[N-1];

endmodule

// D flip-flop module
module dff (
    input  wire clk,
    input  wire d,
    output reg  q
);

always @(posedge clk) begin
    q <= d;
end

endmodule
