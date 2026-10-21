```verilog
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
        if (!rstn) begin
            sync_reg <= {STAGES{1'b0}};
        end else begin
            sync_reg <= {sync_reg[STAGES-2:0], async_sig_i};
        end
    end

    assign sync_sig_o = sync_reg[STAGES-1];

endmodule
```<|im_end|>
