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
    reg [STAGES-1:0] sync_chain_a;
    reg [STAGES-1:0] sync_chain_b;
    reg              pulse_detected;
    reg              busy_reg_a;
    reg              busy_reg_b;

    // Synchronize pulseA_i to clk_a domain
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            sync_chain_a <= 0;
            busy_reg_a   <= 0;
        end else begin
            sync_chain_a <= {sync_chain_a[STAGES-2:0], pulseA_i};
            if (busy_reg_a) begin
                if (!busy_reg_b) begin
                    busy_reg_a <= 0;
                end
            end else begin
                if (sync_chain_a[STAGES-1] && !sync_chain_a[STAGES-2]) begin
                    busy_reg_a <= 1;
                end
            end
        end
    end

    assign busy_o = busy_reg_a;

    // Synchronize sync_chain_a[STAGES-1] to clk_b domain
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            sync_chain_b <= 0;
            pulse_detected <= 0;
            busy_reg_b   <= 0;
        end else begin
            sync_chain_b <= {sync_chain_b[STAGES-2:0], sync_chain_a[STAGES-1]};
            if (sync_chain_b[STAGES-1] && !sync_chain_b[STAGES-2]) begin
                pulse_detected <= 1;
                busy_reg_b     <= 1;
            end else begin
                pulse_detected <= 0;
            end
            if (busy_reg_b && !pulse_detected) begin
                busy_reg_b <= 0;
            end
        end
    end

    // Generate one-cycle pulseB_o
    reg pulseB_o_reg;

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseB_o_reg <= 0;
        end else begin
            pulseB_o_reg <= pulse_detected;
        end
    end

    assign pulseB_o = pulseB_o_reg;

endmodule
