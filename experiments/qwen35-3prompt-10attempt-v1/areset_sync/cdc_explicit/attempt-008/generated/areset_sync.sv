module areset_sync #(
    parameter STAGES = 2
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    reg [STAGES-1:0] rst_pipe;

    always @(posedge clk or posedge async_rst_i) begin
        if (async_rst_i)
            rst_pipe <= {STAGES{1'b1}};
        else
            rst_pipe <= {rst_pipe[STAGES-2:0], rst_pipe[STAGES-1]};
    end

    assign sync_rst_o = rst_pipe[STAGES-1];

endmodule<|im_end|>
