module areset_sync #(
    parameter STAGES = 2
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    // Internal signals for the pipeline stages
    reg [STAGES-1:0] sync_pipeline;

    // Synchronize the async reset through a pipeline of DFFs
    always @(posedge clk or posedge async_rst_i) begin
        if (async_rst_i) begin
            sync_pipeline <= {STAGES{1'b1}};
        end else begin
            sync_pipeline <= {sync_pipeline[STAGES-2:0], 1'b0};
        end
    end

    // Assign the output based on the last stage of the pipeline
    assign sync_rst_o = sync_pipeline[STAGES-1];

endmodule
