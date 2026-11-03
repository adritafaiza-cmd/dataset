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

reg [STAGES-1:0] sync_chain;
reg synced_bit;
reg synced_bit_reg;
reg synced_bit_reg2;

// Instantiate the synchronization chain
always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        sync_chain <= {STAGES{1'b0}};
    end else begin
        sync_chain[0] <= serial_i;
        for (int i = 1; i < STAGES; i = i + 1) begin
            sync_chain[i] <= sync_chain[i-1];
        end
    end
end

assign serial_o = sync_chain[STAGES-1];
assign synced_bit = sync_chain[STAGES-1];

// Register the synchronized bit
always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        synced_bit_reg <= 1'b0;
        synced_bit_reg2 <= 1'b0;
    end else begin
        synced_bit_reg <= synced_bit;
        synced_bit_reg2 <= synced_bit_reg;
    end
end

// Detect rising and falling edges
assign r_edge_o = en_i & ~synced_bit_reg2 & synced_bit_reg;
assign f_edge_o = en_i & synced_bit_reg2 & ~synced_bit_reg;

endmodule
