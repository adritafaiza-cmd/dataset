module synchronizer #(
    parameter STAGES = 2
) (
    input clk,
    input rstn,
    input async_sig_i,
    output sync_sig_o
);

reg [STAGES-1:0] sync_stages;
integer i;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        sync_stages <= {STAGES{1'b0}};
    end else begin
        sync_stages[0] <= async_sig_i;
        for (i = 1; i < STAGES; i = i + 1) begin
            sync_stages[i] <= sync_stages[i-1];
        end
    end
end

assign sync_sig_o = sync_stages[STAGES-1];

endmodule
