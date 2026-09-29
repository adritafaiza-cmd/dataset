module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input clk,
    input async_rst_i,
    output sync_rst_o
);

    reg [CHAINS-1 :0] sync_reg;

    generate
        if (RST_POL) begin : gen_rst_pol_high
            // Active high reset
            always @(posedge clk or posedge async_rst_i) begin
                if (async_rst_i) begin
                    sync_reg <= {CHAINS{1'b1}};
                end else begin
                    sync_reg <= {sync_reg[CHAINS-2 :0], 1'b0};
                end
            end
        end else begin : gen_rst_pol_low
            // Active low reset
            always @(posedge clk or negedge async_rst_i) begin
                if (~async_rst_i) begin
                    sync_reg <= {CHAINS{1'b1}};
                end else begin
                    sync_reg <= {sync_reg[CHAINS-2 :0], 1'b0};
                end
            end
        end
    endgenerate

    assign sync_rst_o = sync_reg[CHAINS-1];

endmodule
