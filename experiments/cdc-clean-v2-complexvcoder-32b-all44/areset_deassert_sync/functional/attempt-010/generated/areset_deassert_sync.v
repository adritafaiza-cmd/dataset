module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    reg [CHAINS-1:0] rst_chain;

    always @(posedge clk) begin
        if (RST_POL == 1'b1) begin
            // Active-high async_rst_i
            if (async_rst_i) begin
                rst_chain <= {CHAINS{1'b1}};
            end else begin
                rst_chain <= rst_chain >> 1;
            end
        end else begin
            // Active-low async_rst_i
            if (~async_rst_i) begin
                rst_chain <= {CHAINS{1'b0}};
            end else begin
                rst_chain <= rst_chain << 1;
            end
        end
    end

    assign sync_rst_o = rst_chain[CHAINS-1];

endmodule
