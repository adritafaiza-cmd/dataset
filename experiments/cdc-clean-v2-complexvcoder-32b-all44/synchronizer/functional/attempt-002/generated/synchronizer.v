module synchronizer #(
    parameter STAGES = 2
)(
    input  clk,
    input  rstn,
    input  async_sig_i,
    output sync_sig_o
);

    // Internal pipeline signal
    reg [STAGES-1:0] sync_pipeline;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            // Reset the pipeline and output to 0 on active-low reset
            sync_pipeline <= {STAGES{1'b0}};
        end else begin
            // Shift the async signal through the pipeline
            sync_pipeline <= {sync_pipeline[STAGES-2:0], async_sig_i};
        end
    end

    // Assign the last stage of the pipeline to the output
    assign sync_sig_o = sync_pipeline[STAGES-1];

endmodule
