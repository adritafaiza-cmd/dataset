```verilog
module synchronizer #(
    parameter STAGES = 2
)(
    input  wire clk,
    input  wire rstn,
    input  wire async_sig_i,
    output wire sync_sig_o
);

    wire [STAGES-1:0] sync_stage;

    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : stage_gen
            assign sync_stage[i] = sync_stage[i-1] ? async_sig_i : sync_stage[i-1];
        end
    endgenerate

    assign sync_sig_o = sync_stage[STAGES-1];

endmodule
```<|im_end|>
