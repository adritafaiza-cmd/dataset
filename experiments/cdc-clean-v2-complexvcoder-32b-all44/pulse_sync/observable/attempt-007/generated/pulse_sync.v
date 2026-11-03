module pulse_sync #(
    parameter STAGES = 2
)(
    input  clk_a,
    input  rstn_a,
    input  clk_b,
    input  rstn_b,
    input  pulseA_i,
    output reg pulseB_o,
    output reg busy_o
);

reg pulseA_synced_b;
reg pulseB_synced_a;
reg pulseA_edge_det;
reg pulseB_edge_det;

// Sync cell instances for crossing between clk_a and clk_b
sync_cell #(.STAGES(STAGES)) sync_cell_inst_a_to_b (
    .clk(clk_b),
    .rstn(rstn_b),
    .async_in(pulseA_i),
    .sync_out(pulseA_synced_b)
);

sync_cell #(.STAGES(STAGES)) sync_cell_inst_b_to_a (
    .clk(clk_a),
    .rstn(rstn_a),
    .async_in(pulseB_o),
    .sync_out(pulseB_synced_a)
);

// Detect rising edge of pulseA_i in clk_a domain
always @(posedge clk_a or negedge rstn_a) begin
    if (!rstn_a) begin
        pulseA_edge_det <= 0;
    end else begin
        pulseA_edge_det <= pulseA_i & ~pulseA_synced_b;
    end
end

// Generate pulseB_o in clk_b domain and set busy_o
always @(posedge clk_b or negedge rstn_b) begin
    if (!rstn_b) begin
        pulseB_o <= 0;
    end else if (pulseA_synced_b & ~pulseB_synced_a & ~busy_o) begin
        pulseB_o <= 1;
        busy_o <= 1;
    end else if (pulseB_synced_a) begin
        pulseB_o <= 0;
    end
end

// Detect rising edge of pulseB_o in clk_b domain
always @(posedge clk_a or negedge rstn_a) begin
    if (!rstn_a) begin
        pulseB_edge_det <= 0;
    end else begin
        pulseB_edge_det <= pulseB_synced_a;
    end
end

// Clear busy_o when pulseB_o is detected in clk_a domain
always @(posedge clk_a or negedge rstn_a) begin
    if (!rstn_a) begin
        busy_o <= 0;
    end else if (pulseB_edge_det) begin
        busy_o <= 0;
    end
end

endmodule

module sync_cell #(
    parameter STAGES = 2
)(
    input  clk,
    input  rstn,
    input  async_in,
    output reg sync_out
);

reg [STAGES-1:0] sync_chain;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        sync_chain <= 0;
    end else begin
        sync_chain[0] <= async_in;
        for (integer i = 1; i < STAGES; i = i + 1) begin
            sync_chain[i] <= sync_chain[i-1];
        end
    end
end

assign sync_out = sync_chain[STAGES-1];

endmodule
