module areset_sync #(
    parameter STAGES = 2
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    reg [STAGES-1:0] sync_pipeline;

    always @(posedge clk) begin
        sync_pipeline[0] <= async_rst_i;
        for (int i = 1; i < STAGES; i = i + 1) begin
            sync_pipeline[i] <= sync_pipeline[i-1];
        end
    end

    assign sync_rst_o = sync_pipeline[STAGES-1];

endmodule
