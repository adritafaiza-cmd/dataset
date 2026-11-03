module synchronizer #(
    parameter STAGES = 2
)(
    input  clk,
    input  rstn,
    input  async_sig_i,
    output sync_sig_o
);

    wire [STAGES-1:0] sync_chain;

    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : gen_ff_stages
            if (i == 0) begin
                ff_stage ff_stage_inst (
                    .clk(clk),
                    .rstn(rstn),
                    .d(async_sig_i),
                    .q(sync_chain[i])
                );
            end else begin
                ff_stage ff_stage_inst (
                    .clk(clk),
                    .rstn(rstn),
                    .d(sync_chain[i-1]),
                    .q(sync_chain[i])
                );
            end
        end
    endgenerate

    assign sync_sig_o = sync_chain[STAGES-1];

endmodule

module ff_stage (
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
