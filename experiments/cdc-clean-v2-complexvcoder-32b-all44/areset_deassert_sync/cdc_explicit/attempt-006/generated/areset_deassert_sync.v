module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    // Internal signals
    reg [CHAINS:0] rst_sync;

    // Synchronize the reset signal
    always @(posedge clk or posedge async_rst_i) begin
        if (async_rst_i == RST_POL) begin
            rst_sync <= {CHAINS+1{RST_POL}};
        end else begin
            rst_sync <= {rst_sync[CHAINS-1:0], 1'b0};
        end
    end

    // Assign the output reset signal
    assign sync_rst_o = rst_sync[CHAINS];

endmodule
