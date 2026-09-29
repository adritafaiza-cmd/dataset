module areset_sync #(
    parameter STAGES = 2
) (
    input clk,
    input async_rst_i,
    output sync_rst_o
);

    reg [STAGES-1:0] sync_reg;

    generate
        genvar i;
        for (i = 0; i < STAGES; i = i + 1) begin : gen_sync
            if (i == 0) begin
                // First stage: D is 0
                always @(posedge clk or posedge async_rst_i) begin
                    if (async_rst_i)
                        sync_reg[i] <= 1'b1;
                    else
                        sync_reg[i] <= 1'b0;
                end
            end else begin
                // Subsequent stages: D is previous stage's Q
                always @(posedge clk or posedge async_rst_i) begin
                    if (async_rst_i)
                        sync_reg[i] <= 1'b1;
                    else
                        sync_reg[i] <= sync_reg[i-1];
                end
            end
        end
    endgenerate

    assign sync_rst_o = sync_reg[STAGES-1];

endmodule
