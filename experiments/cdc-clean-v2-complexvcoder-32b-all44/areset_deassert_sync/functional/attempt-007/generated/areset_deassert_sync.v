module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    // Internal signal to hold the pipeline stages
    reg [CHAINS:0] rst_pipeline;

    always @(posedge clk) begin
        // First stage of the pipeline directly follows the async reset
        rst_pipeline[0] <= async_rst_i ^ ~RST_POL;

        // Shift the pipeline
        for (integer i = 1; i <= CHAINS; i = i + 1) begin
            rst_pipeline[i] <= rst_pipeline[i-1];
        end
    end

    // Output the last stage of the pipeline
    assign sync_rst_o = rst_pipeline[CHAINS] ^ ~RST_POL;

endmodule
