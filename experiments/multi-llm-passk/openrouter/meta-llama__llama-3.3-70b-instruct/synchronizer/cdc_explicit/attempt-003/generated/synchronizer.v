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
        sync_reg <= {async_sig_i, sync_reg[STAGES-1:1]};
        sync_sig_o <= sync_reg[0];
    end
end

endmodule
