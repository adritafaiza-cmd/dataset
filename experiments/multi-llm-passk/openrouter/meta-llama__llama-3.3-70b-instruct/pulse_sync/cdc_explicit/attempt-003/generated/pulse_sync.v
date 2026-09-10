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

reg [STAGES-1:0] sync_pulse_a;
reg [STAGES-1:0] sync_pulse_b;
reg busy_a;
reg busy_b;

always @(posedge clk_a or negedge rstn_a) begin
    if (~rstn_a) begin
        sync_pulse_a <= {STAGES{1'b0}};
        busy_a <= 1'b0;
    end else begin
        sync_pulse_a[0] <= pulseA_i & ~busy_a;
        for (int i = 1; i < STAGES; i++) begin
            sync_pulse_a[i] <= sync_pulse_a[i-1];
        end
        busy_a <= sync_pulse_a[STAGES-1] | busy_a;
    end
end

always @(posedge clk_b or negedge rstn_b) begin
    if (~rstn_b) begin
        sync_pulse_b <= {STAGES{1'b0}};
        busy_b <= 1'b0;
        pulseB_o <= 1'b0;
    end else begin
        sync_pulse_b[0] <= sync_pulse_a[STAGES-1];
        for (int i = 1; i < STAGES; i++) begin
            sync_pulse_b[i] <= sync_pulse_b[i-1];
        end
        busy_b <= sync_pulse_b[STAGES-1] | busy_b;
        pulseB_o <= sync_pulse_b[STAGES-1] & ~sync_pulse_b[STAGES-2];
    end
end

assign busy_o = busy_a | busy_b;

endmodule
