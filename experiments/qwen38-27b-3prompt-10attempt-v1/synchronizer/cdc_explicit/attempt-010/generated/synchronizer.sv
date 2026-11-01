module synchronizer #(
    parameter STAGES = 2
)(
    input  clk,
    input  rstn,
    input  async_sig_i,
    output sync_sig_o
);

    localparam MIN_STAGES = 2;
    localparam ACTUAL_STAGES = (STAGES < MIN_STAGES) ? MIN_STAGES : STAGES;

    reg [ACTUAL_STAGES-1:0] sync_reg;

    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            sync_reg <= {ACTUAL_STAGES{1'b0}};
        else
            sync_reg <= {sync_reg[ACTUAL_STAGES-2:0], async_sig_i};
    end

    assign sync_sig_o = sync_reg[ACTUAL_STAGES-1];

endmodule
