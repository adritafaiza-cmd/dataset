module areset_sync #(
    parameter STAGES = 2
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    // Internal signal for connecting stages
    wire [STAGES-1:0] sync_stages;

    // First stage directly connects to the async_rst_i
    stage stage_0 (
        .clk(clk),
        .async_rst_i(async_rst_i),
        .sync_rst_o(sync_stages[0])
    );

    // Generate the remaining stages
    genvar i;
    generate
        for (i = 1; i < STAGES; i = i + 1) begin : gen_stages
            stage stage_i (
                .clk(clk),
                .async_rst_i(sync_stages[i-1]),
                .sync_rst_o(sync_stages[i])
            );
        end
    endgenerate

    // Final stage output is the synchronized reset
    assign sync_rst_o = sync_stages[STAGES-1];

endmodule

module stage (
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    reg sync_rst;

    always @(posedge clk or posedge async_rst_i) begin
        if (async_rst_i)
            sync_rst <= 1'b1;
        else
            sync_rst <= 1'b0;
    end

    assign sync_rst_o = sync_rst;

endmodule
