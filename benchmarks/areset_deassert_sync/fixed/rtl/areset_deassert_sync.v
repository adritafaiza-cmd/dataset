// Async-assert / sync-deassert reset. Verilog rewrite of
// tweak_circuits areset_deassert_sync.vhd. Designed by Mitu Raj.

module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    (* ASYNC_REG = "TRUE" *)
    reg [CHAINS-1:0] flipflops;
    wire rst_assert = (async_rst_i == RST_POL);

    assign sync_rst_o = flipflops[CHAINS-1];

    always @(posedge clk or posedge rst_assert) begin
        if (rst_assert)
            flipflops <= {CHAINS{RST_POL}};
        else
            flipflops <= {flipflops[CHAINS-2:0], ~RST_POL};
    end

endmodule
