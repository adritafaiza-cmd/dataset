module synchronizer #(
    parameter STAGES = 2
)(
    input  clk,
    input  rstn,
    input  async_sig_i,
    output sync_sig_o
);

reg [STAGES-1:0] sync_ff;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        sync_ff <= {STAGES{1'b0}};
    end else begin
        sync_ff[0] <= async_sig_i;
        for (int i = 1; i < STAGES; i = i + 1) begin
            sync_ff[i] <= sync_ff[i-1];
        end
    end
end

assign sync_sig_o = sync_ff[STAGES-1];

endmodule
