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
reg pulseA_i_sync;
reg pulseA_i_sync_reg;
reg pulseB_o_sync;
reg pulseB_o_sync_reg;
reg pulseA_i_ff;
reg pulseA_i_ff_reg;
reg pulseB_o_reg;
reg busy_o_reg;

// Instantiate sync_ff modules
sync_ff #(.STAGES(STAGES)) sync_ff_inst_a_to_b (
    .clk(clk_b),
    .rstn(rstn_b),
    .d(pulseA_i_sync),
    .q(pulseA_i_sync_reg)
);

sync_ff #(.STAGES(STAGES)) sync_ff_inst_b_to_a (
    .clk(clk_a),
    .rstn(rstn_a),
    .d(pulseB_o_sync),
    .q(pulseB_o_sync_reg)
);

// Synchronize pulseA_i to clk_b domain
always @(posedge clk_a or negedge rstn_a) begin
    if (!rstn_a) begin
        pulseA_i_sync <= 1'b0;
        pulseA_i_ff <= 1'b0;
        pulseA_i_ff_reg <= 1'b0;
    end else begin
        pulseA_i_sync <= pulseA_i;
        pulseA_i_ff <= pulseA_i_sync;
        pulseA_i_ff_reg <= pulseA_i_ff;
    end
end

// Detect rising edge of pulseA_i in clk_a domain
wire pulseA_i_rising_edge = pulseA_i_ff & ~pulseA_i_ff_reg;

// Generate pulseB_o in clk_b domain
always @(posedge clk_b or negedge rstn_b) begin
    if (!rstn_b) begin
        pulseB_o_reg <= 1'b0;
        pulseB_o_sync <= 1'b0;
    end else if (pulseA_i_sync_reg & ~busy_o_reg) begin
        pulseB_o_reg <= 1'b1;
        pulseB_o_sync <= 1'b1;
    end else begin
        pulseB_o_reg <= 1'b0;
        pulseB_o_sync <= pulseB_o_reg;
    end
end

// Generate busy_o in clk_a domain
always @(posedge clk_a or negedge rstn_a) begin
    if (!rstn_a) begin
        busy_o_reg <= 1'b0;
    end else if (pulseA_i_rising_edge) begin
        busy_o_reg <= 1'b1;
    end else if (pulseB_o_sync_reg) begin
        busy_o_reg <= 1'b0;
    end
end

// Assign outputs
assign pulseB_o = pulseB_o_reg;
assign busy_o = busy_o_reg;

endmodule

module sync_ff #(
    parameter STAGES = 2
)(
    input  clk,
    input  rstn,
    input  d,
    output q
);

reg [STAGES-1:0] d_reg;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        d_reg <= {STAGES{1'b0}};
    end else begin
        d_reg <= {d_reg[STAGES-2:0], d};
    end
end

assign q = d_reg[STAGES-1];

endmodule
