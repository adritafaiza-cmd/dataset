// Level reset synchronizer. Verilog rewrite of tweak_circuits areset_sync.vhd.
// Designed by Mitu Raj, Chipmunk Logic.

module areset_sync #(
    parameter STAGES = 2
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    (* ASYNC_REG = "TRUE" *)
    reg [STAGES-1:0] flipflops;

    assign sync_rst_o = flipflops[STAGES-1];

    always @(posedge clk)
        flipflops <= {flipflops[STAGES-2:0], async_rst_i};

endmodule
