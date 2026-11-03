module areset_sync #(
    parameter STAGES = 2
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    // Internal signals for synchronization stages
    wire [STAGES-1:0] sync_stage;

    // Instantiate the synchronization stages
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : gen_sync_stages
            if (i == 0) begin : first_stage
                sync_stage sync_stage_inst_0 (
                    .clk(clk),
                    .d(async_rst_i),
                    .q(sync_stage[0])
                );
            end else begin : subsequent_stages
                sync_stage sync_stage_inst_i (
                    .clk(clk),
                    .d(sync_stage[i-1]),
                    .q(sync_stage[i])
                );
            end
        end
    endgenerate

    // Assign the final synchronized reset output
    assign sync_rst_o = sync_stage[STAGES-1];

endmodule

module sync_stage (
    input  clk,
    input  d,
    output q
);

    reg q_reg;

    always @(posedge clk) begin
        q_reg <= d;
    end

    assign q = q_reg;

endmodule
