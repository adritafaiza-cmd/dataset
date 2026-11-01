module areset_sync #(
    parameter STAGES = 2
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    localparam WIDTH = (STAGES > 0) ? STAGES : 1;

    reg [WIDTH-1:0] sync_reg;

    always @(posedge clk or posedge async_rst_i) begin
        if (async_rst_i)
            sync_reg <= {WIDTH{1'b1}};
        else
            sync_reg <= {sync_reg[WIDTH-2:0], 1'b0};
    end

    assign sync_rst_o = sync_reg[WIDTH-1];

endmodule
