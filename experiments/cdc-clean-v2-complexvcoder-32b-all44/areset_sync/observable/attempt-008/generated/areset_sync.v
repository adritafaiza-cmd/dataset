module areset_sync #(
    parameter STAGES = 2
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

reg [STAGES-1:0] sync_chain;

genvar i;
generate
    for (i = 0; i < STAGES; i = i + 1) begin : gen_sync_stages
        if (i == 0) begin
            sync_stage u_sync_stage_0 (
                .clk(clk),
                .async_in(async_rst_i),
                .sync_out(sync_chain[0])
            );
        end else begin
            sync_stage u_sync_stage_i (
                .clk(clk),
                .async_in(sync_chain[i-1]),
                .sync_out(sync_chain[i])
            );
        end
    end
endgenerate

assign sync_rst_o = sync_chain[STAGES-1];

endmodule

module sync_stage (
    input  clk,
    input  async_in,
    output sync_out
);

reg sync_ff;

always @(posedge clk or posedge async_in) begin
    if (async_in) begin
        sync_ff <= 1'b1;
    end else begin
        sync_ff <= 1'b0;
    end
end

assign sync_out = sync_ff;

endmodule
