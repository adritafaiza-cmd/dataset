module areset_sync #(
    parameter STAGES = 2
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    wire [STAGES-1:0] sync_stages;

    // Instantiate the first sync stage
    sync_stage stage_0 (
        .clk        (clk),
        .async_rst_i(async_rst_i),
        .sync_rst_o (sync_stages[0])
    );

    // Instantiate the remaining sync stages
    genvar i;
    generate
        for (i = 1; i < STAGES; i = i + 1) begin : gen_sync_stages
            sync_stage stage_i (
                .clk        (clk),
                .async_rst_i(sync_stages[i-1]),
                .sync_rst_o (sync_stages[i])
            );
        end
    endgenerate

    // Assign the final synchronized reset output
    assign sync_rst_o = sync_stages[STAGES-1];

endmodule

module sync_stage (
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    reg d_ff;

    always @(posedge clk or posedge async_rst_i) begin
        if (async_rst_i)
            d_ff <= 1'b1;
        else
            d_ff <= 1'b0;
    end

    assign sync_rst_o = d_ff;

endmodule
