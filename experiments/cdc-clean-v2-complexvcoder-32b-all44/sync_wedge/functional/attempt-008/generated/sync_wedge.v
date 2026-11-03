module sync_wedge #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  en_i,
    input  serial_i,
    output r_edge_o,
    output f_edge_o,
    output serial_o
);

    wire sync_chain_out;
    reg  d1, d2, d3;

    sync_chain #(
        .STAGES(STAGES)
    ) sync_chain_inst (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .async_in(serial_i),
        .sync_out(sync_chain_out)
    );

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            d1 <= 1'b0;
            d2 <= 1'b0;
            d3 <= 1'b0;
        end else begin
            d1 <= sync_chain_out;
            d2 <= d1;
            d3 <= d2;
        end
    end

    assign serial_o = sync_chain_out;
    assign r_edge_o = en_i & (d2 & ~d3);
    assign f_edge_o = en_i & (~d2 & d3);

endmodule

module sync_chain #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  async_in,
    output sync_out
);

    reg [STAGES-1:0] sync_chain;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_chain <= {STAGES{1'b0}};
        end else begin
            sync_chain[0] <= async_in;
            sync_chain[STAGES-1:1] <= sync_chain[STAGES-2:0];
        end
    end

    assign sync_out = sync_chain[STAGES-1];

endmodule
