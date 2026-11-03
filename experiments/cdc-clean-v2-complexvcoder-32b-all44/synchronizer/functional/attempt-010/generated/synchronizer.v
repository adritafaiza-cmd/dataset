module synchronizer #(
    parameter STAGES = 2
)(
    input  clk,
    input  rstn,
    input  async_sig_i,
    output sync_sig_o
);

    // Internal pipeline stages
    reg [STAGES-1:0] sync_pipeline;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sync_pipeline <= {STAGES{1'b0}};
        end else begin
            sync_pipeline[0] <= async_sig_i;
            for (integer i = 1; i < STAGES; i = i + 1) begin
                sync_pipeline[i] <= sync_pipeline[i-1];
            end
        end
    end

    assign sync_sig_o = sync_pipeline[STAGES-1];

endmodule
