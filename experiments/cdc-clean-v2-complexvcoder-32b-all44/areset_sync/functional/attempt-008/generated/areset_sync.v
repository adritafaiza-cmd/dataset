module areset_sync #(
    parameter STAGES = 2
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    reg [STAGES-1:0] rst_sync_pipeline;

    always @(posedge clk or posedge async_rst_i) begin
        if (async_rst_i) begin
            rst_sync_pipeline <= {STAGES{1'b1}};
        end else begin
            rst_sync_pipeline <= {rst_sync_pipeline[STAGES-2:0], 1'b0};
        end
    end

    assign sync_rst_o = rst_sync_pipeline[STAGES-1];

endmodule
