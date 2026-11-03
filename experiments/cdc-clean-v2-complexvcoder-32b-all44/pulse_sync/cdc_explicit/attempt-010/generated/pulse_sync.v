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

    reg [STAGES-1:0] sync_ff_a;
    reg              pulseA_sync;
    reg              pulseA_edge;
    reg              pulseA_pulse;
    reg              pulseA_busy;

    reg [STAGES-1:0] sync_ff_b;
    reg              pulseB_sync;
    reg              pulseB_pulse;

    // Synchronize pulseA_i into clk_a domain
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            sync_ff_a <= 0;
        end else begin
            sync_ff_a <= {sync_ff_a[STAGES-2:0], pulseA_i};
        end
    end

    assign pulseA_sync = sync_ff_a[STAGES-1];

    // Detect edge on synchronized pulseA_i
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            pulseA_edge <= 0;
        end else begin
            pulseA_edge <= pulseA_sync & ~pulseA_busy;
        end
    end

    // Generate single-cycle pulse
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            pulseA_pulse <= 0;
        end else begin
            pulseA_pulse <= pulseA_edge;
        end
    end

    // Busy signal indicates a pulse is in flight
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            pulseA_busy <= 0;
        end else if (pulseA_pulse) begin
            pulseA_busy <= 1;
        end else if (pulseB_pulse) begin
            pulseA_busy <= 0;
        end
    end

    assign busy_o = pulseA_busy;

    // Synchronize pulseA_pulse into clk_b domain
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            sync_ff_b <= 0;
        end else begin
            sync_ff_b <= {sync_ff_b[STAGES-2:0], pulseA_pulse};
        end
    end

    assign pulseB_sync = sync_ff_b[STAGES-1];

    // Generate single-cycle pulse in clk_b domain
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseB_pulse <= 0;
        end else begin
            pulseB_pulse <= pulseB_sync;
        end
    end

    assign pulseB_o = pulseB_pulse;

endmodule
