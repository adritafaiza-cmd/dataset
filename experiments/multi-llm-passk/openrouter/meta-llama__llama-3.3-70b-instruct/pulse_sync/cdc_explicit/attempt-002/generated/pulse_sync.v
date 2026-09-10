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

reg [STAGES-1:0] sync_reg_a;
reg [STAGES-1:0] sync_reg_b;
reg             pulse_a_sync;
reg             pulse_b_sync;
reg             busy_reg;

always @(posedge clk_a or negedge rstn_a) begin
    if (!rstn_a) begin
        sync_reg_a <= {STAGES{1'b0}};
        pulse_a_sync <= 1'b0;
    end else begin
        sync_reg_a <= {pulseA_i, sync_reg_a[STAGES-2:0]};
        pulse_a_sync <= sync_reg_a[STAGES-1];
    end
end

always @(posedge clk_b or negedge rstn_b) begin
    if (!rstn_b) begin
        sync_reg_b <= {STAGES{1'b0}};
        pulse_b_sync <= 1'b0;
        busy_reg <= 1'b0;
    end else begin
        sync_reg_b <= {pulse_a_sync, sync_reg_b[STAGES-2:0]};
        pulse_b_sync <= sync_reg_b[STAGES-1];
        busy_reg <= pulse_a_sync || busy_reg;
    end
end

assign pulseB_o = pulse_b_sync;
assign busy_o = busy_reg;

endmodule
