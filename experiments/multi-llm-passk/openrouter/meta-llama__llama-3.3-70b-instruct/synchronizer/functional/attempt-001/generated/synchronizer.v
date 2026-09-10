module synchronizer #(
    parameter STAGES = 2
)(
    input  clk,
    input  rstn,
    input  async_sig_i,
    output reg sync_sig_o
);

reg [STAGES-1:0] sync_reg;

always @(posedge clk or negedge rstn) begin
    if (~rstn) begin
        sync_reg <= {STAGES{1'b0}};
        sync_sig_o <= 1'b0;
    end else begin
        sync_reg[0] <= async_sig_i;
        for (int i = 1; i < STAGES; i++) begin
            sync_reg[i] <= sync_reg[i-1];
        end
        sync_sig_o <= sync_reg[STAGES-1];
    end
end

endmodule
