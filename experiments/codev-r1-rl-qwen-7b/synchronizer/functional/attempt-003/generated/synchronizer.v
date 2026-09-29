module synchronizer #(
    parameter STAGES = 2
)(
    input  clk,
    input  rstn,
    input  async_sig_i,
    output sync_sig_o
);

    reg [STAGES-1 :0] sync_reg;

    genvar i;
    generate
        for (i=0; i < STAGES; i=i+1) begin : gen_sync
            if (i == 0) begin
                // First stage: input is async_sig_i
                always @(posedge clk or negedge rstn) begin
                    if (!rstn) begin
                        sync_reg[i] <= 1'b0;
                    end else begin
                        sync_reg[i] <= async_sig_i;
                    end
                end
            end else begin
                // Subsequent stages: input is previous stage
                always @(posedge clk or negedge rstn) begin
                    if (!rstn) begin
                        sync_reg[i] <= 1'b0;
                    end else begin
                        sync_reg[i] <= sync_reg[i-1];
                    end
                end
            end
        end
    endgenerate

    assign sync_sig_o = sync_reg[STAGES-1];

endmodule
