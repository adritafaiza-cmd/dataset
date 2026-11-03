module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    // Internal signal to capture the output of the reset_sync_chain module
    wire rst_sync_chain_out;

    // Instantiate the reset_sync_chain module
    reset_sync_chain #(
        .CHAINS(CHAINS),
        .RST_POL(RST_POL)
    ) rst_sync_chain_inst (
        .clk(clk),
        .rst_in(async_rst_i),
        .rst_out(rst_sync_chain_out)
    );

    // Assign the output of the reset_sync_chain to the output port
    assign sync_rst_o = rst_sync_chain_out;

endmodule

module reset_sync_chain #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  rst_in,
    output rst_out
);

    // Internal pipeline chain for synchronization
    reg [CHAINS-1:0] sync_chain;

    // Synchronize the reset signal using a pipeline chain
    always @(posedge clk) begin
        sync_chain[0] <= rst_in;
        for (int i = 1; i < CHAINS; i = i + 1) begin
            sync_chain[i] <= sync_chain[i-1];
        end
    end

    // Assign the last stage of the pipeline chain to the output
    assign rst_out = sync_chain[CHAINS-1];

endmodule
