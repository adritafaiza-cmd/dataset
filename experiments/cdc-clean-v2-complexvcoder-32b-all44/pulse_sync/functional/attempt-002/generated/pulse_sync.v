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

    // Internal signals
    reg    pulseA_i_synced;
    reg    pulseA_synced_b;
    reg    pulseA_edge_detect;
    reg    pulseA_edge_detected;
    reg    pulseB_o_reg;
    reg    pulseB_o_synced;
    reg    busy_o_synced;

    // Sync stages from clk_a to clk_b
    sync_stage #(.STAGES(STAGES)) sync_stage_a2b (
        .clk(clk_b),
        .rstn(rstn_b),
        .din(pulseA_i_synced),
        .dout(pulseA_synced_b)
    );

    // Sync stages from clk_b to clk_a
    sync_stage #(.STAGES(STAGES)) sync_stage_b2a (
        .clk(clk_a),
        .rstn(rstn_a),
        .din(pulseB_o_reg),
        .dout(pulseB_o_synced)
    );

    // Edge detection logic in clk_b domain
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseA_i_synced <= 1'b0;
        end else begin
            pulseA_i_synced <= pulseA_i;
        end
    end

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseA_edge_detect <= 1'b0;
        end else begin
            pulseA_edge_detect <= pulseA_synced_b & ~pulseA_i_synced;
        end
    end

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseA_edge_detected <= 1'b0;
        end else begin
            pulseA_edge_detected <= pulseA_edge_detect;
        end
    end

    // Busy signal logic in clk_a domain
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            busy_o_synced <= 1'b0;
        end else begin
            busy_o_synced <= pulseB_o_synced;
        end
    end

    assign busy_o = pulseA_edge_detected | busy_o_synced;

    // Output pulse logic in clk_b domain
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseB_o_reg <= 1'b0;
        end else if (pulseA_edge_detect) begin
            pulseB_o_reg <= 1'b1;
        end else begin
            pulseB_o_reg <= 1'b0;
        end
    end

    assign pulseB_o = pulseB_o_reg;

endmodule

module sync_stage #(
    parameter STAGES = 2
)(
    input  clk,
    input  rstn,
    input  din,
    output dout
);

    reg [STAGES-1:0] sync_chain;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sync_chain <= {STAGES{1'b0}};
        end else begin
            sync_chain <= {sync_chain[STAGES-2:0], din};
        end
    end

    assign dout = sync_chain[STAGES-1];

endmodule
