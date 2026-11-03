module synchronizer #(
    parameter STAGES = 2
)(
    input  clk,
    input  rstn,
    input  async_sig_i,
    output sync_sig_o
);

    // Internal signal to connect the stages
    wire [STAGES-2:0] sync_stages;

    // First stage
    sync_stage #(
        .STAGES(1)
    ) stage_0 (
        .clk(clk),
        .rstn(rstn),
        .async_sig_i(async_sig_i),
        .sync_sig_o(sync_stages[0])
    );

    // Intermediate stages
    genvar i;
    generate
        for (i = 1; i < STAGES-1; i = i + 1) begin : gen_sync_stages
            sync_stage #(
                .STAGES(1)
            ) stage_i (
                .clk(clk),
                .rstn(rstn),
                .async_sig_i(sync_stages[i-1]),
                .sync_sig_o(sync_stages[i])
            );
        end
    endgenerate

    // Last stage
    sync_stage #(
        .STAGES(1)
    ) stage_last (
        .clk(clk),
        .rstn(rstn),
        .async_sig_i(sync_stages[STAGES-2]),
        .sync_sig_o(sync_sig_o)
    );

endmodule

module sync_stage #(
    parameter STAGES = 1
)(
    input  clk,
    input  rstn,
    input  async_sig_i,
    output sync_sig_o
);

    reg reg_sync;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            reg_sync <= 1'b0;
        end else begin
            reg_sync <= async_sig_i;
        end
    end

    assign sync_sig_o = reg_sync;

endmodule
