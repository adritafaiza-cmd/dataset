module areset_sync #(
    parameter STAGES = 2
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    // Internal pipeline registers
    reg [STAGES-1:0] sync_rst_pipeline;

    // Synchronous reset pipeline
    always @(posedge clk) begin
        sync_rst_pipeline[0] <= async_rst_i;
        for (integer i = 1; i < STAGES; i = i + 1) begin
            sync_rst_pipeline[i] <= sync_rst_pipeline[i-1];
        end
    end

    // Assign the final stage of the pipeline to the output
    assign sync_rst_o = sync_rst_pipeline[STAGES-1];

endmodule
