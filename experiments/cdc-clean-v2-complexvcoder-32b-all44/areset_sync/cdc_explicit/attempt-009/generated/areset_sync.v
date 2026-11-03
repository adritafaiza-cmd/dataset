module areset_sync #(
    parameter STAGES = 2
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    wire [STAGES-1:0] rst_pipeline;

    // First stage directly driven by async_rst_i
    sync_stage stage_0 (
        .clk(clk),
        .async_rst_i(async_rst_i),
        .sync_rst_o(rst_pipeline[0])
    );

    // Generate remaining stages
    genvar i;
    generate
        for (i = 1; i < STAGES; i = i + 1) begin : gen_stages
            sync_stage stage_i (
                .clk(clk),
                .async_rst_i(rst_pipeline[i-1]),
                .sync_rst_o(rst_pipeline[i])
            );
        end
    endgenerate

    // Assign the final stage to the output
    assign sync_rst_o = rst_pipeline[STAGES-1];

endmodule

module sync_stage (
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    reg sync_rst;

    always @(posedge clk) begin
        sync_rst <= async_rst_i;
    end

    assign sync_rst_o = sync_rst;

endmodule
