```verilog
module synchronizer #(
    parameter STAGES = 2
)(
    input  clk,
    input  rstn,
    input  async_sig_i,
    output sync_sig_o
);

    reg [STAGES-1:0] pipeline_reg;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            pipeline_reg <= {STAGES{1'b0}};
        end else begin
            pipeline_reg <= {pipeline_reg[STAGES-2:0], async_sig_i};
        end
    end

    assign sync_sig_o = pipeline_reg[STAGES-1];

endmodule
```<|im_end|>
