module synchronizer #(
    parameter STAGES = 2
)(
    input  clk,
    input  rstn,
    input  async_sig_i,
    output sync_sig_o
);

reg [STAGES-1:0] sync_chain;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        sync_chain <= {STAGES{1'b0}};
    end else begin
        sync_chain[0] <= async_sig_i;
        sync_chain[STAGES-1:1] <= sync_chain[STAGES-2:0];
    end
end

assign sync_sig_o = sync_chain[STAGES-1];

endmodule
