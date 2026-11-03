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
    reg pulseA_synced;
    reg pulseB_synced;
    reg pulseA_detected;
    reg pulseB_detected;
    reg busy;

    // Instantiate ff_sync for crossing pulseA_i from clk_a to clk_b
    ff_sync ff_sync_a2b (
        .clk(clk_b),
        .rstn(rstn_b),
        .d(pulseA_i),
        .q(pulseA_synced)
    );

    // Instantiate ff_sync for crossing pulseB_o from clk_b to clk_a
    ff_sync ff_sync_b2a (
        .clk(clk_a),
        .rstn(rstn_a),
        .d(pulseB_o),
        .q(pulseB_synced)
    );

    // Detect rising edge of pulseA_i in clk_a domain
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            pulseA_detected <= 0;
        end else begin
            pulseA_detected <= pulseA_i & !pulseA_synced;
        end
    end

    // Detect rising edge of pulseB_o in clk_a domain
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            pulseB_detected <= 0;
        end else begin
            pulseB_detected <= pulseB_synced & !pulseB_o;
        end
    end

    // Set busy when pulseA_synced is detected and clear it when pulseB_detected is detected
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            busy <= 0;
        end else begin
            if (pulseA_detected) begin
                busy <= 1;
            end else if (pulseB_detected) begin
                busy <= 0;
            end
        end
    end

    // Drive busy_o with busy signal in clk_a domain
    assign busy_o = busy;

    // Set pulseB_o on rising edge of pulseA_synced in clk_b domain if not busy
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseB_o <= 0;
        end else begin
            if (pulseA_synced & !busy) begin
                pulseB_o <= 1;
            end else begin
                pulseB_o <= 0;
            end
        end
    end

endmodule

module ff_sync (
    input  clk,
    input  rstn,
    input  d,
    output q
);

    // Internal flip-flops for synchronization
    reg ff1;
    reg ff2;

    // Synchronize input signal d to the output q using two flip-flops in the same clock domain
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            ff1 <= 0;
            ff2 <= 0;
        end else begin
            ff1 <= d;
            ff2 <= ff1;
        end
    end

    assign q = ff2;

endmodule
