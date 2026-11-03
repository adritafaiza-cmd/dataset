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

reg [STAGES-1:0] sync_chain_a;
reg [STAGES-1:0] sync_chain_b;
reg              pulseA_sync;
reg              pulseA_prev;
reg              busy;
reg              busy_synced;

// Asynchronous crossing chain from clk_a to clk_b
always @(posedge clk_a or negedge rstn_a) begin
    if (!rstn_a) begin
        sync_chain_a <= {STAGES{1'b0}};
    end else begin
        sync_chain_a <= {sync_chain_a[STAGES-2:0], pulseA_i};
    end
end

assign pulseA_sync = sync_chain_a[STAGES-1];

// Detect rising edge of pulseA_sync in clk_b domain
always @(posedge clk_b or negedge rstn_b) begin
    if (!rstn_b) begin
        pulseA_prev <= 1'b0;
    end else begin
        pulseA_prev <= pulseA_sync;
    end
end

// Busy signal generation
always @(posedge clk_a or negedge rstn_a) begin
    if (!rstn_a) begin
        busy <= 1'b0;
    end else begin
        if (pulseA_sync && !pulseA_prev) begin
            busy <= 1'b1;
        end else if (!busy_synced) begin
            busy <= 1'b0;
        end
    end
end

assign busy_o = busy;

// Asynchronous crossing chain from clk_a to clk_b for busy signal
always @(posedge clk_b or negedge rstn_b) begin
    if (!rstn_b) begin
        sync_chain_b <= {STAGES{1'b0}};
    end else begin
        sync_chain_b <= {sync_chain_b[STAGES-2:0], busy};
    end
end

assign busy_synced = sync_chain_b[STAGES-1];

// Pulse detector in clk_b domain
reg pulseB;

always @(posedge clk_b or negedge rstn_b) begin
    if (!rstn_b) begin
        pulseB <= 1'b0;
    end else begin
        if (pulseA_sync && !pulseA_prev && !busy_synced) begin
            pulseB <= 1'b1;
        end else begin
            pulseB <= 1'b0;
        end
    end
end

assign pulseB_o = pulseB;

endmodule
