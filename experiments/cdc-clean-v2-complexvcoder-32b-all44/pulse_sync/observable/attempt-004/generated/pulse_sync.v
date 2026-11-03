module pulse_sync #(
    parameter STAGES = 2
)(
    input  clk_a,
    input  rstn_a,
    input  clk_b,
    input  rstn_b,
    input  pulseA_i,
    output pulseB_o,
    output busy_o
);

reg sync_pulseA_to_b;
reg sync_pulseB_to_a;
reg pulseA_edge;
reg pulseB_edge;
reg busy;
reg pulseA_reg;
reg pulseB_reg;

// Synchronize pulseA_i from clk_a domain to clk_b domain
ff_sync ff_sync_inst_a_to_b (
    .clk(clk_b),
    .rstn(rstn_b),
    .d(pulseA_i),
    .q(sync_pulseA_to_b)
);

// Synchronize pulseB_o from clk_b domain to clk_a domain
ff_sync ff_sync_inst_b_to_a (
    .clk(clk_a),
    .rstn(rstn_a),
    .d(pulseB_o),
    .q(sync_pulseB_to_a)
);

// Clock domain clk_a
always @(posedge clk_a or negedge rstn_a) begin
    if (!rstn_a) begin
        pulseA_reg <= 1'b0;
        busy <= 1'b0;
    end else begin
        pulseA_reg <= pulseA_i;
        pulseA_edge <= pulseA_i & ~pulseA_reg;
        if (pulseA_edge && !sync_pulseB_to_a) begin
            busy <= 1'b1;
        end
    end
end

// Clock domain clk_b
always @(posedge clk_b or negedge rstn_b) begin
    if (!rstn_b) begin
        pulseB_reg <= 1'b0;
        pulseB_o <= 1'b0;
    end else begin
        pulseB_reg <= sync_pulseA_to_b;
        pulseB_edge <= sync_pulseA_to_b & ~pulseB_reg;
        if (pulseB_edge) begin
            pulseB_o <= 1'b1;
            if (!sync_pulseB_to_a) begin
                busy <= 1'b0;
            end
        end else begin
            pulseB_o <= 1'b0;
        end
    end
end

assign busy_o = busy;

endmodule

module ff_sync (
    input clk,
    input rstn,
    input d,
    output q
);

reg reg1;
reg reg2;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        reg1 <= 1'b0;
        reg2 <= 1'b0;
    end else begin
        reg1 <= d;
        reg2 <= reg1;
    end
end

assign q = reg2;

endmodule
