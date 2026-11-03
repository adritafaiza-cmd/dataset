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

    wire pulseA_i_synced;
    wire pulseA_i_synced_reg;
    wire pulseB_o_reg;
    wire pulseB_o_synced;
    reg  busy_o_reg;

    // Synchronize pulseA_i from clk_a domain to clk_b domain
    ff_sync #(.STAGES(STAGES)) ff_sync_inst_a_to_b (
        .clk(clk_b),
        .rstn(rstn_b),
        .d(pulseA_i),
        .q(pulseA_i_synced)
    );

    // Synchronize pulseB_o from clk_b domain to clk_a domain
    ff_sync #(.STAGES(STAGES)) ff_sync_inst_b_to_a (
        .clk(clk_a),
        .rstn(rstn_a),
        .d(pulseB_o_reg),
        .q(pulseB_o_synced)
    );

    // Register to hold the synced pulseA_i in clk_b domain
    reg pulseA_i_synced_reg_reg;

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseA_i_synced_reg <= 1'b0;
            pulseA_i_synced_reg_reg <= 1'b0;
            pulseB_o_reg <= 1'b0;
        end else begin
            pulseA_i_synced_reg <= pulseA_i_synced;
            pulseA_i_synced_reg_reg <= pulseA_i_synced_reg;
            if (pulseA_i_synced_reg && !pulseA_i_synced_reg_reg && !pulseB_o_synced) begin
                pulseB_o_reg <= 1'b1;
            end else if (pulseB_o_synced) begin
                pulseB_o_reg <= 1'b0;
            end
        end
    end

    // Busy signal logic in clk_a domain
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            busy_o_reg <= 1'b0;
        end else begin
            if (pulseA_i && !busy_o_reg) begin
                busy_o_reg <= 1'b1;
            end else if (pulseB_o_synced) begin
                busy_o_reg <= 1'b0;
            end
        end
    end

    assign pulseB_o = pulseB_o_reg;
    assign busy_o = busy_o_reg;

endmodule

// Synchronizer module
module ff_sync #(
    parameter STAGES = 2
)(
    input  clk,
    input  rstn,
    input  d,
    output q
);

    reg [STAGES-1:0] sync_reg;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sync_reg <= {STAGES{1'b0}};
        end else begin
            sync_reg <= {sync_reg[STAGES-2:0], d};
        end
    end

    assign q = sync_reg[STAGES-1];

endmodule
