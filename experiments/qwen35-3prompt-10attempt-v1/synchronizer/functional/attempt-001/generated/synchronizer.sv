module synchronizer #(
    parameter STAGES = 2
)(
    input  clk,
    input  rstn,
    input  async_sig_i,
    output sync_sig_o
);

    reg [STAGES-1:0] sync_pipe;

    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            sync_pipe <= {STAGES{1'b0}};
        else
            sync_pipe <= {sync_pipe[STAGES-2:0], async_sig_i};
    end

    assign sync_sig_o = sync_pipe[STAGES-1];

endmodule<|im_end|>
