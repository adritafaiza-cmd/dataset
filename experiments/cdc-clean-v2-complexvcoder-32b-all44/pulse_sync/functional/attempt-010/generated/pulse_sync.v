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

reg [STAGES-1:0] pulse_sync_chain_a;
reg [STAGES-1:0] pulse_sync_chain_b;
reg              pulse_detected;
reg              busy;

always @(posedge clk_a or negedge rstn_a) begin
    if (!rstn_a) begin
        pulse_sync_chain_a <= {STAGES{1'b0}};
        pulse_detected     <= 1'b0;
        busy               <= 1'b0;
    end else begin
        pulse_sync_chain_a <= {pulse_sync_chain_a[STAGES-2:0], pulseA_i};
        if (!busy) begin
            pulse_detected <= pulse_sync_chain_a[STAGES-1] & ~pulse_sync_chain_a[STAGES-2];
            busy           <= pulse_detected;
        end else if (pulse_sync_chain_b[STAGES-1]) begin
            busy           <= 1'b0;
        end
    end
end

always @(posedge clk_b or negedge rstn_b) begin
    if (!rstn_b) begin
        pulse_sync_chain_b <= {STAGES{1'b0}};
        pulseB_o           <= 1'b0;
    end else begin
        pulse_sync_chain_b <= {pulse_sync_chain_b[STAGES-2:0], pulse_sync_chain_a[STAGES-1]};
        pulseB_o           <= pulse_sync_chain_b[STAGES-1] & ~pulse_sync_chain_b[STAGES-2];
    end
end

assign busy_o = busy;

endmodule
