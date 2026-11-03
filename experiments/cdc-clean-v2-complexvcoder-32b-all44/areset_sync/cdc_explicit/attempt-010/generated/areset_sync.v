module areset_sync #(
    parameter STAGES = 2
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    wire [STAGES-1:0] sync_stages;

    // First stage directly connects to async_rst_i
    sync_stage sync_stage_0 (
        .clk(clk),
        .async_rst_i(async_rst_i),
        .sync_rst_o(sync_stages[0])
    );

    // Generate remaining stages
    genvar i;
    generate
        for (i = 1; i < STAGES; i = i + 1) begin : gen_sync_stages
            sync_stage sync_stage_i (
                .clk(clk),
                .async_rst_i(sync_stages[i-1]),
                .sync_rst_o(sync_stages[i])
            );
        end
    endgenerate

    // Assign the final stage to the output
    assign sync_rst_o = sync_stages[STAGES-1];

endmodule

module sync_stage (
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    reg sync_rst_reg;

    always @(posedge clk) begin
        sync_rst_reg <= async_rst_i;
    end

    assign sync_rst_o = sync_rst_reg;

endmodule
