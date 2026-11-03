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
    reg sync_pulseA_b;
    reg sync_pulseB_a;
    reg edge_detect_a;
    reg edge_detect_b;
    reg busy_flag_a;
    reg busy_flag_b;

    // Synchronizers
    sync_ff #(.STAGES(STAGES)) sync_ff_inst_a (
        .clk(clk_b),
        .rstn(rstn_b),
        .async_in(pulseA_i),
        .sync_out(sync_pulseA_b)
    );

    sync_ff #(.STAGES(STAGES)) sync_ff_inst_b (
        .clk(clk_a),
        .rstn(rstn_a),
        .async_in(pulseB_o),
        .sync_out(sync_pulseB_a)
    );

    // Edge detection and busy flag management for clk_a domain
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            edge_detect_a <= 0;
            busy_flag_a <= 0;
        end else begin
            edge_detect_a <= pulseA_i;
            if (!busy_flag_a && pulseA_i && !edge_detect_a) begin
                busy_flag_a <= 1;
                sync_pulseA_b <= 1;
            end
        end
    end

    // Edge detection and busy flag management for clk_b domain
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            edge_detect_b <= 0;
            busy_flag_b <= 0;
            pulseB_o <= 0;
        end else begin
            edge_detect_b <= sync_pulseA_b;
            if (!busy_flag_b && sync_pulseA_b && !edge_detect_b) begin
                busy_flag_b <= 1;
                pulseB_o <= 1;
            end
            if (sync_pulseB_a) begin
                busy_flag_b <= 0;
                pulseB_o <= 0;
            end
        end
    end

    // Busy output
    assign busy_o = busy_flag_a;

endmodule

module sync_ff #(
    parameter STAGES = 2
)(
    input  clk,
    input  rstn,
    input  async_in,
    output sync_out
);

    // Internal shift register
    reg [STAGES-1:0] shift_reg;

    // Synchronization logic
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            shift_reg <= 0;
        end else begin
            shift_reg <= {shift_reg[STAGES-2:0], async_in};
        end
    end

    // Output the last stage of the shift register
    assign sync_out = shift_reg[STAGES-1];

endmodule
