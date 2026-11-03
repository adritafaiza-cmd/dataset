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

    reg [STAGES-1:0] sync_chain_a_to_b;
    reg [STAGES-1:0] sync_chain_b_to_a;
    reg              pulseA_sync;
    reg              pulseB_sync;
    reg              busy;

    // Synchronize pulseA_i from clk_a to clk_b
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            sync_chain_a_to_b <= {STAGES{1'b0}};
        end else begin
            sync_chain_a_to_b <= {sync_chain_a_to_b[STAGES-2:0], pulseA_i};
        end
    end

    assign pulseA_sync = sync_chain_a_to_b[STAGES-1];

    // Generate pulseB_o on rising edge of pulseA_sync
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseB_o <= 1'b0;
        end else if (pulseA_sync && !sync_chain_a_to_b[STAGES-2]) begin
            pulseB_o <= 1'b1;
        end else begin
            pulseB_o <= 1'b0;
        end
    end

    // Synchronize pulseB_o from clk_b to clk_a
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            sync_chain_b_to_a <= {STAGES{1'b0}};
        end else begin
            sync_chain_b_to_a <= {sync_chain_b_to_a[STAGES-2:0], pulseB_o};
        end
    end

    assign pulseB_sync = sync_chain_b_to_a[STAGES-1];

    // Generate busy_o while pulse is in flight
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            busy <= 1'b0;
        end else if (pulseA_i) begin
            busy <= 1'b1;
        end else if (pulseB_sync) begin
            busy <= 1'b0;
        end
    end

    assign busy_o = busy;

endmodule
