module areset_sync #(
    parameter STAGES = 2
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    // Internal signals for each stage of synchronization
    wire [STAGES-1:0] sync_stages;

    // First stage synchronizer
    reset_sync_stage #(
        .STAGES(1)
    ) reset_sync_stage_0 (
        .clk(clk),
        .async_rst_i(async_rst_i),
        .sync_rst_o(sync_stages[0])
    );

    // Intermediate stages synchronizers
    genvar i;
    generate
        for (i = 1; i < STAGES; i = i + 1) begin : gen_sync_stages
            reset_sync_stage #(
                .STAGES(1)
            ) reset_sync_stage_i (
                .clk(clk),
                .async_rst_i(sync_stages[i-1]),
                .sync_rst_o(sync_stages[i])
            );
        end
    endgenerate

    // Final output assignment
    assign sync_rst_o = sync_stages[STAGES-1];

endmodule

module reset_sync_stage #(
    parameter STAGES = 1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    reg sync_rst;

    always @(posedge clk or posedge async_rst_i) begin
        if (async_rst_i) begin
            sync_rst <= 1'b1;
        end else begin
            sync_rst <= 1'b0;
        end
    end

    assign sync_rst_o = sync_rst;

endmodule
