module areset_sync #(
    parameter STAGES = 2
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    wire [STAGES-1:0] sync_stages;

    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : gen_sync_stages
            if (i == 0) begin : first_stage
                sync_stage u_sync_stage (
                    .clk      (clk),
                    .async_in (async_rst_i),
                    .sync_out (sync_stages[0])
                );
            end else begin : other_stages
                sync_stage u_sync_stage (
                    .clk      (clk),
                    .async_in (sync_stages[i-1]),
                    .sync_out (sync_stages[i])
                );
            end
        end
    endgenerate

    assign sync_rst_o = sync_stages[STAGES-1];

endmodule

module sync_stage (
    input  clk,
    input  async_in,
    output sync_out
);

    reg sync_out_reg;

    always @(posedge clk) begin
        sync_out_reg <= async_in;
    end

    assign sync_out = sync_out_reg;

endmodule
