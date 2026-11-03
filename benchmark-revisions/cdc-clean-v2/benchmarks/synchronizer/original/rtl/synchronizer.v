// Single-bit multi-flop synchronizer. Verilog rewrite of
// tweak_circuits synchronizer.vhd. Designed by Mitu Raj.

module synchronizer #(
    parameter STAGES = 2
)(
    input  clk,
    input  rstn,
    input  async_sig_i,
    output sync_sig_o
);

    (* ASYNC_REG = "TRUE" *)
    reg [STAGES-1:0] flipflops;

    always @(posedge clk) begin
        if (!rstn)
            flipflops <= {STAGES{1'b0}};
        else
            flipflops <= {flipflops[STAGES-2:0], async_sig_i};
    end

    assign sync_sig_o = flipflops[STAGES-1];

endmodule
