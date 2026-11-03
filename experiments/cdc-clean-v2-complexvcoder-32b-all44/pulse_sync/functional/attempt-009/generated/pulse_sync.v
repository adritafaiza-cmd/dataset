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

    wire sync_pulse_a_to_b;
    wire sync_pulse_b_to_a;
    reg  [STAGES-1:0] sync_ffs_a_to_b;
    reg  [STAGES-1:0] sync_ffs_b_to_a;
    reg  pulseA_d;
    reg  pulseA_edge;
    reg  fifo;
    reg  fifo_d;
    reg  fifo_pulse;
    reg  fifo_pulse_d;

    // Synchronize pulseA_i from clk_a domain to clk_b domain
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            sync_ffs_a_to_b <= {STAGES{1'b0}};
        end else begin
            sync_ffs_a_to_b <= {sync_ffs_a_to_b[STAGES-2:0], pulseA_i};
        end
    end
    assign sync_pulse_a_to_b = sync_ffs_a_to_b[STAGES-1];

    // Detect rising edge of pulseA_i
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            pulseA_d <= 1'b0;
            pulseA_edge <= 1'b0;
        end else begin
            pulseA_d <= pulseA_i;
            pulseA_edge <= pulseA_i & ~pulseA_d;
        end
    end

    // FIFO logic in clk_a domain
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            fifo <= 1'b0;
            fifo_d <= 1'b0;
            fifo_pulse <= 1'b0;
            fifo_pulse_d <= 1'b0;
        end else begin
            fifo_d <= fifo;
            fifo_pulse_d <= fifo_pulse;
            if (pulseA_edge && !fifo) begin
                fifo <= 1'b1;
                fifo_pulse <= 1'b1;
            end else if (sync_pulse_b_to_a) begin
                fifo <= 1'b0;
                fifo_pulse <= 1'b0;
            end
        end
    end
    assign busy_o = fifo_d;

    // Synchronize fifo_pulse from clk_a domain to clk_b domain
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            sync_ffs_b_to_a <= {STAGES{1'b0}};
        end else begin
            sync_ffs_b_to_a <= {sync_ffs_b_to_a[STAGES-2:0], fifo_pulse};
        end
    end
    assign sync_pulse_b_to_a = sync_ffs_b_to_a[STAGES-1];

    // PulseB_o generation in clk_b domain
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseB_o <= 1'b0;
        end else begin
            pulseB_o <= sync_pulse_b_to_a;
        end
    end

endmodule
