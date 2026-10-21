module synchronizer #(
    parameter STAGES = 2
)(
    input  clk,
    input  rstn,
    input  async_sig_i,
    output sync_sig_o
);

    // Internal signal to hold the synchronized value
    reg sync_sig_i;

    // Two-stage synchronizer chain for CDC compliance
    // Stage 1
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            sync_sig_i <= 1'b0;
        else
            sync_sig_i <= async_sig_i;
    end

    // Stage 2
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            sync_sig_o <= 1'b0;
        else
            sync_sig_o <= sync_sig_i;
    end

endmodule<|im_end|>
