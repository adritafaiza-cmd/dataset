module areset_sync #(
    parameter STAGES = 2
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    wire ff_sync_inst_0_q;
    wire ff_sync_inst_1_q;

    ff_sync #(
        .STAGES(1)
    ) ff_sync_inst_0 (
        .clk(clk),
        .d(async_rst_i),
        .q(ff_sync_inst_0_q)
    );

    ff_sync #(
        .STAGES(1)
    ) ff_sync_inst_1 (
        .clk(clk),
        .d(ff_sync_inst_0_q),
        .q(ff_sync_inst_1_q)
    );

    assign sync_rst_o = ff_sync_inst_1_q;

endmodule

module ff_sync #(
    parameter STAGES = 1
)(
    input  clk,
    input  d,
    output q
);

    reg [STAGES-1:0] sync_ffs;

    always @(posedge clk) begin
        sync_ffs[0] <= d;
        for (int i = 1; i < STAGES; i = i + 1) begin
            sync_ffs[i] <= sync_ffs[i-1];
        end
    end

    assign q = sync_ffs[STAGES-1];

endmodule
