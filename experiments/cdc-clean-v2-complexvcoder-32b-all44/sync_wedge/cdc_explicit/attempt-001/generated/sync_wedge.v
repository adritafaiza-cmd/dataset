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

    // Internal signals
    reg synced_bit;
    reg prev_synced_bit;

    // Instantiate the sync_chain module
    sync_chain #(
        .STAGES(STAGES)
    ) sync_chain_inst (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .async_in(serial_i),
        .synced_out(synced_bit)
    );

    // Register the synced_bit to detect edges
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            prev_synced_bit <= 1'b0;
            serial_o <= 1'b0;
        end else begin
            prev_synced_bit <= synced_bit;
            serial_o <= synced_bit;
        end
    end

    // Detect rising and falling edges
    assign r_edge_o = en_i & (synced_bit & ~prev_synced_bit);
    assign f_edge_o = en_i & (~synced_bit & prev_synced_bit);

endmodule

module sync_chain #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  async_in,
    output synced_out
);

    // Internal signal array for synchronization stages
    reg [STAGES-1:0] synced_bits;

    // Synchronization chain
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            synced_bits <= {STAGES{1'b0}};
        end else begin
            synced_bits[0] <= async_in;
            for (int i = 1; i < STAGES; i = i + 1) begin
                synced_bits[i] <= synced_bits[i-1];
            end
        end
    end

    // Output the last stage of the synchronization chain
    assign synced_out = synced_bits[STAGES-1];

endmodule
