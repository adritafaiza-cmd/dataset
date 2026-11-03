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

    reg [STAGES-1:0] sync_ff_a_to_b;
    reg [STAGES-1:0] sync_ff_b_to_a;

    // Synchronize pulseA_i from clk_a to clk_b
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            sync_ff_a_to_b <= 0;
        end else begin
            sync_ff_a_to_b <= {sync_ff_a_to_b[STAGES-2:0], pulseA_i};
        end
    end

    // Synchronize pulseB_o from clk_b to clk_a
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            sync_ff_b_to_a <= 0;
        end else begin
            sync_ff_b_to_a <= {sync_ff_b_to_a[STAGES-2:0], sync_ff_a_to_b[STAGES-1]};
        end
    end

    // Generate pulseB_o
    reg pulseB_o_reg;
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseB_o_reg <= 0;
        end else begin
            pulseB_o_reg <= sync_ff_a_to_b[STAGES-1] & ~sync_ff_b_to_a[STAGES-1];
        end
    end

    // Assign output
    assign pulseB_o = pulseB_o_reg;

    // Generate busy_o
    assign busy_o = sync_ff_a_to_b[STAGES-1] | pulseB_o_reg;

endmodule
