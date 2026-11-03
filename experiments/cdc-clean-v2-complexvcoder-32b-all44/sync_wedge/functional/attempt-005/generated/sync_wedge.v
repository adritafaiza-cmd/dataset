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
    reg  synced_bit_d1;
    reg  synced_bit_d2;

    // Instantiate the sync_chain module
    sync_chain #(
        .STAGES(STAGES)
    ) sync_chain_inst (
        .clk(clk_i),
        .rst_ni(rst_ni),
        .async_in(serial_i),
        .sync_out(synced_bit)
    );

    // Register the synced bit to detect edges
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            synced_bit_d1 <= 1'b0;
            synced_bit_d2 <= 1'b0;
        end else begin
            synced_bit_d1 <= synced_bit;
            synced_bit_d2 <= synced_bit_d1;
        end
    end

    // Assign outputs
    assign serial_o = synced_bit;
    assign r_edge_o = en_i & (synced_bit_d1 & ~synced_bit_d2);
    assign f_edge_o = en_i & (~synced_bit_d1 & synced_bit_d2);

endmodule

module sync_chain #(
    parameter STAGES = 2
)(
    input  clk,
    input  rst_ni,
    input  async_in,
    output sync_out
);

    reg [STAGES-1:0] sync_chain_reg;

    // Synchronize the asynchronous input using multiple stages of flip-flops
    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_chain_reg <= {STAGES{1'b0}};
        end else begin
            sync_chain_reg[0] <= async_in;
            for (int i = 1; i < STAGES; i = i + 1) begin
                sync_chain_reg[i] <= sync_chain_reg[i-1];
            end
        end
    end

    // Output the synchronized signal
    assign sync_out = sync_chain_reg[STAGES-1];

endmodule
