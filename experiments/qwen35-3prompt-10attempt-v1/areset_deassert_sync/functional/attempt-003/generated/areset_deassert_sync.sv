module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    localparam int unsigned STAGE_COUNT = CHAINS;
    localparam int unsigned STAGE_MASK = (1 << STAGE_COUNT) - 1;

    reg [STAGE_COUNT - 1:0] rst_pipe;

    always @(posedge clk or posedge async_rst_i) begin
        if (async_rst_i) begin
            if (RST_POL) begin
                rst_pipe <= STAGE_MASK;
            end else begin
                rst_pipe <= 0;
            end
        end else begin
            rst_pipe <= {rst_pipe[STAGE_COUNT - 2:0], rst_pipe[STAGE_COUNT - 1]};
        end
    end

    assign sync_rst_o = rst_pipe[STAGE_COUNT - 1];

endmodule<|im_end|>
