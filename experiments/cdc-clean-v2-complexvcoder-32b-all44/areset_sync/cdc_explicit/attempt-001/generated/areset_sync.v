module areset_sync #(
    parameter STAGES = 2
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    // Internal pipeline signal
    reg [STAGES-1:0] rst_pipeline;

    // Synchronize the asynchronous reset to the synchronous clock domain
    always @(posedge clk or posedge async_rst_i) begin
        if (async_rst_i) begin
            rst_pipeline <= {STAGES{1'b1}};
        end else begin
            rst_pipeline <= {rst_pipeline[STAGES-2:0], 1'b0};
        end
    end

    // Assign the output reset based on the pipeline stages
    assign sync_rst_o = rst_pipeline[STAGES-1];

endmodule
