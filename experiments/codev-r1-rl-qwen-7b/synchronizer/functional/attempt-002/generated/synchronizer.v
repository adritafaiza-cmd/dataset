module synchronizer #(
    parameter STAGES = 2
) (
    input clk,
    input rstn,
    input async_sig_i,
    output sync_sig_o
);

reg [STAGES-1:0] sync_reg;
integer i;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        sync_reg <= 0;
    end else begin
        sync_reg[0] <= async_sig_i;
        for (i = 1; i < STAGES; i = i + 1) begin
            sync_reg[i] <= sync_reg[i-1];
        end
    end
end

assign sync_sig_o = sync_reg[STAGES-1];

endmodule
