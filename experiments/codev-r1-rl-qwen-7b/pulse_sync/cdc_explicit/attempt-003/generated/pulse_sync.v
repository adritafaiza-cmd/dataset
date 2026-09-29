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

    // Domain A signals
    reg toggle_a;
    reg busy_a;

    // Synchronize toggle to B
    reg [STAGES-1:0] sync_toggle_b;

    // Domain B signals
    reg [STAGES-1:0] sync_toggle;

    // Edge detection in B
    wire pulseB;

    // Synchronize pulseB to A
    reg [STAGES-1:0] sync_pulseB_a;

    // Assign outputs
    assign busy_o = busy_a;
    assign pulseB_o = pulseB;

    // Domain A logic
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            toggle_a <= 0;
            busy_a <= 0;
        end else begin
            // If pulseA comes and not busy, toggle and set busy
            if (pulseA_i && !busy_a) begin
                toggle_a <= ~toggle_a;
                busy_a <= 1;
            end
            // Clear busy when ack arrives (synchronized pulseB)
            if (sync_pulseB_a[STAGES-1]) begin
                busy_a <= 0;
            end
        end
    end

    // Synchronize toggle_a to B
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            sync_toggle <= 0;
        end else begin
            sync_toggle <= {sync_toggle[STAGES-2:0], toggle_a};
        end
    end

    // Edge detection in B (toggle)
    assign pulseB = (sync_toggle[STAGES-1] ^ sync_toggle[STAGES-2]);

    // Synchronize pulseB to A
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            sync_pulseB_a <= 0;
        end else begin
            sync_pulseB_a <= {sync_pulseB_a[STAGES-2:0], pulseB};
        end
    end

endmodule
