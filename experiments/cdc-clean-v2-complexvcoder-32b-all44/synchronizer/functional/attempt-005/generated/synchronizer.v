module synchronizer #(
    parameter STAGES = 2
)(
    input  clk,
    input  rstn,
    input  async_sig_i,
    output sync_sig_o
);

    // Internal signals to connect the stages
    wire [STAGES-2:0] stage_sync;

    // First stage
    synchronizer_stage stage_0 (
        .clk(clk),
        .rstn(rstn),
        .async_sig_i(async_sig_i),
        .sync_sig_o(stage_sync[0])
    );

    // Intermediate stages
    genvar i;
    generate
        for (i = 1; i < STAGES-1; i = i + 1) begin : gen_stages
            synchronizer_stage stage_i (
                .clk(clk),
                .rstn(rstn),
                .async_sig_i(stage_sync[i-1]),
                .sync_sig_o(stage_sync[i])
            );
        end
    endgenerate

    // Last stage
    synchronizer_stage stage_last (
        .clk(clk),
        .rstn(rstn),
        .async_sig_i(stage_sync[STAGES-2]),
        .sync_sig_o(sync_sig_o)
    );

endmodule

module synchronizer_stage (
    input  clk,
    input  rstn,
    input  async_sig_i,
    output sync_sig_o
);

    reg sync_reg;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sync_reg <= 1'b0;
        end else begin
            sync_reg <= async_sig_i;
        end
    end

    assign sync_sig_o = sync_reg;

endmodule
