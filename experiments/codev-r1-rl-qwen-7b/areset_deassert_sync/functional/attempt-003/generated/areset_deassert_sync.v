module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    reg [CHAINS-1:0] sync_reg;

    generate
        if (RST_POL) begin
            // Active high reset
            always @(posedge clk or posedge async_rst_i) begin
                if (async_rst_i) begin
                    sync_reg <= {CHAINS{1'b1}};
                end else begin
                    sync_reg <= (sync_reg << 1);
                end
            end
        end else begin
            // Active low reset
            always @(posedge clk or negedge async_rst_i) begin
                if (~async_rst_i) begin
                    sync_reg <= {CHAINS{1'b1}};
                end else begin
                    sync_reg <= (sync_reg << 1);
                end
            end
        end
    endgenerate

    assign sync_rst_o = |sync_reg;

endmodule
