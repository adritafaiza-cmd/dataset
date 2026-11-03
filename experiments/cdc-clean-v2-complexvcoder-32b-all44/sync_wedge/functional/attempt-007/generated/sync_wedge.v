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

    wire synced_bit;
    reg  d_bit, dd_bit;
    reg  r_edge, f_edge;

    sync_chain #(
        .STAGES(STAGES)
    ) sync_chain_inst (
        .clk_i    (clk_i),
        .rst_ni   (rst_ni),
        .async_in (serial_i),
        .synced_out (synced_bit)
    );

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            d_bit  <= 1'b0;
            dd_bit <= 1'b0;
            r_edge <= 1'b0;
            f_edge <= 1'b0;
        end else begin
            d_bit  <= synced_bit;
            dd_bit <= d_bit;
            r_edge <= en_i & (~dd_bit & d_bit);
            f_edge <= en_i & (dd_bit & ~d_bit);
        end
    end

    assign serial_o = synced_bit;
    assign r_edge_o = r_edge;
    assign f_edge_o = f_edge;

endmodule

module sync_chain #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  async_in,
    output synced_out
);

    reg [STAGES-1:0] sync_chain;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_chain <= {STAGES{1'b0}};
        end else begin
            sync_chain[0] <= async_in;
            for (integer i = 1; i < STAGES; i = i + 1) begin
                sync_chain[i] <= sync_chain[i-1];
            end
        end
    end

    assign synced_out = sync_chain[STAGES-1];

endmodule
