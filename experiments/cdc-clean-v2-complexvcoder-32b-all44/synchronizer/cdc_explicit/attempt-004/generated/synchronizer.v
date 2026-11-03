module synchronizer #(
    parameter STAGES = 2
)(
    input  clk,
    input  rstn,
    input  async_sig_i,
    output sync_sig_o
);

    wire [STAGES-1:0] sync_pipeline;

    // First stage directly connected to the asynchronous input
    sync_stage stage_0 (
        .clk(clk),
        .rstn(rstn),
        .d(async_sig_i),
        .q(sync_pipeline[0])
    );

    // Generate the remaining stages
    genvar i;
    generate
        for (i = 1; i < STAGES; i = i + 1) begin : gen_stages
            sync_stage stage_i (
                .clk(clk),
                .rstn(rstn),
                .d(sync_pipeline[i-1]),
                .q(sync_pipeline[i])
            );
        end
    endgenerate

    // Assign the final stage to the output
    assign sync_sig_o = sync_pipeline[STAGES-1];

endmodule

module sync_stage (
    input  clk,
    input  rstn,
    input  d,
    output q
);

    reg q_reg;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            q_reg <= 1'b0;
        end else begin
            q_reg <= d;
        end
    end

    assign q = q_reg;

endmodule
