```verilog
`timescale 1ns / 1ps

module synchronizer #(
    parameter STAGES = 2
)(
    input  wire clk,
    input  wire rstn,
    input  wire async_sig_i,
    output wire sync_sig_o
);

    wire [STAGES-1:0] sync_pipe;

    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : stage_gen
            assign sync_pipe[i] = sync_pipe[i-1];
        end
    endgenerate

    // Handle the first stage separately to handle the initial reset state correctly
    // and chain the rest.
    // Stage 0: Input -> FF
    // Stage 1: Stage 0 -> FF
    // ...
    // Stage N-1: Stage N-2 -> FF -> Output

    // We need to instantiate flip-flops. Since we cannot use vendor primitives,
    // we use standard DFF logic.
    // To ensure the output is low on reset, we rely on the default 0 initialization
    // of registers in Verilog-2001 when rstn is asserted.

    // First stage
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            sync_pipe[0] <= 1'b0;
        else
            sync_pipe[0] <= async_sig_i;
    end

    // Subsequent stages
    genvar j;
    generate
        for (j = 1; j < STAGES; j = j + 1) begin : stage_gen_loop
            always @(posedge clk or negedge rstn) begin
                if (!rstn)
                    sync_pipe[j] <= 1'b0;
                else
                    sync_pipe[j] <= sync_pipe[j-1];
            end
        end
    endgenerate

    assign sync_sig_o = sync_pipe[STAGES-1];

endmodule
```<|im_end|>
