module areset_sync #(
    parameter STAGES = 2
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    reg [STAGES-1:0] rst_sync_stage;

    always @(posedge clk) begin
        rst_sync_stage[0] <= async_rst_i;
        for (int i = 1; i < STAGES; i = i + 1) begin
            rst_sync_stage[i] <= rst_sync_stage[i-1];
        end
    end

    assign sync_rst_o = rst_sync_stage[STAGES-1];

endmodule
