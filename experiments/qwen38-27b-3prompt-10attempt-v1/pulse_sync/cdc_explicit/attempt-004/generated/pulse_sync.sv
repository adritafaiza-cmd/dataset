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

    // Domain A: level signal to be synchronized to domain B
    reg level_a;
    wire level_a_nxt;

    // Domain B: synchronized level signal
    reg [STAGES-1:0] level_b_sync;
    wire level_b;

    // Domain B: edge detection
    reg level_b_prev;
    wire pulseB_o;

    // Domain B: busy signal
    reg busy_b;
    wire busy_o;

    // Domain A: busy signal synchronized back
    reg [STAGES-1:0] busy_a_sync;
    wire busy_a;

    // Domain A: level generation logic
    // Set level_a when pulseA_i is received and not busy
    // Clear level_a when busy_a indicates the pulse has been processed in domain B
    assign level_a_nxt = (pulseA_i && !busy_a) ? 1'b1 :
                         (busy_a) ? 1'b0 :
                         level_a;

    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a)
            level_a <= 1'b0;
        else
            level_a <= level_a_nxt;
    end

    // Synchronize level_a to domain B
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b)
            level_b_sync <= {STAGES{1'b0}};
        else
            level_b_sync <= {level_b_sync[STAGES-2:0], level_a};
    end

    assign level_b = level_b_sync[STAGES-1];

    // Edge detection in domain B
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b)
            level_b_prev <= 1'b0;
        else
            level_b_prev <= level_b;
    end

    assign pulseB_o = level_b & ~level_b_prev;

    // Busy signal in domain B: high when level_b is high (pulse in flight)
    // We set busy_b when we detect the rising edge, and clear it when level_b goes low
    // Actually, busy should be high while the pulse is in flight.
    // The pulse is in flight from when level_a is set until level_b is cleared.
    // In domain B, we can track busy as: high when level_b is high.
    // But we need to clear it after the pulse is generated.
    // Let's use: busy_b is set on rising edge of level_b, cleared on falling edge.
    // Actually, simpler: busy_b = level_b. But we need to synchronize back to A.
    // Let's define busy_b as high when level_b is high.
    
    assign busy_b = level_b;

    // Synchronize busy_b back to domain A
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a)
            busy_a_sync <= {STAGES{1'b0}};
        else
            busy_a_sync <= {busy_a_sync[STAGES-2:0], busy_b};
    end

    assign busy_a = busy_a_sync[STAGES-1];

    // Output busy_o in domain B
    assign busy_o = busy_b;

endmodule
