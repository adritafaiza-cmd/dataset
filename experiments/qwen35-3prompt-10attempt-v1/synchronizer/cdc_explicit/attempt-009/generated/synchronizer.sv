module synchronizer #(
    parameter STAGES = 2
)(
    input  wire clk,
    input  wire rstn,
    input  wire async_sig_i,
    output wire sync_sig_o
);

    reg [STAGES-1:0] sync_reg;

    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            sync_reg <= {STAGES{1'b0}};
        else begin
            sync_reg[0] <= async_sig_i;
            sync_reg[1:STAGES-1] <= sync_reg[STAGES-2:STAGES-1];
        end
    end

    assign sync_sig_o = sync_reg[STAGES-1];

endmodule<|im_end|>
