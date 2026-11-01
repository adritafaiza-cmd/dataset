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

    // Domain A: latch the pulse and generate a level signal
    reg a_latch;
    wire a_level;

    // Domain B: synchronizer chain
    reg [STAGES-1:0] b_sync;
    reg b_prev;
    reg b_latch;

    // busy_o is high while a pulse is in flight (from A latch until B latch clears)
    // We track the in-flight state in domain B for busy_o, but we need to
    // coordinate with domain A to prevent new pulses.

    // Strategy:
    // 1. In domain A, when pulseA_i arrives and we are not busy, set a_latch.
    // 2. a_latch is a level signal that stays high until domain B acknowledges.
    // 3. In domain B, synchronize a_latch through STAGES flip-flops.
    // 4. Detect rising edge of the synchronized signal to generate pulseB_o.
    // 5. After generating pulseB_o, clear a_latch (via a clear signal synchronized back to A).
    // 6. busy_o is high from when a_latch is set in A until it is cleared.

    // Let's use a handshake approach:
    // - a_req: set by pulseA_i in domain A when not busy
    // - b_ack: set in domain B after detecting the pulse, then cleared
    // - a_req is cleared when b_ack is seen in domain A

    // Simpler approach:
    // - a_latch: set on pulseA_i when not busy, cleared when b_ack_sync is high in domain A
    // - b_sync: STAGES-stage synchronizer of a_latch
    // - pulseB_o: rising edge of b_sync[STAGES-1]
    // - b_latch: set on rising edge of b_sync[STAGES-1], cleared when b_ack is generated
    // - b_ack: set when b_latch is set, cleared when b_ack_sync is high in domain B

    // Actually, let's use a simpler one-shot approach:
    // Domain A:
    //   - a_latch: set on pulseA_i when !busy_a, cleared when ack_a is high
    //   - busy_a: a_latch (high while waiting for ack)
    // Domain B:
    //   - b_sync: STAGES-stage sync of a_latch
    //   - b_edge: rising edge of b_sync[STAGES-1]
    //   - b_latch: set on b_edge, cleared when ack_b is high
    //   - pulseB_o: b_edge
    //   - ack_b: b_latch (high while waiting for ack to be seen in A)
    //   - busy_o: b_latch (high while pulse is in flight in B)
    // Domain A:
    //   - ack_a_sync: STAGES-stage sync of ack_b
    //   - a_latch cleared when ack_a_sync is high
    //   - busy_o should be high while either a_latch or b_latch is high

    // Let me reconsider. The busy_o should be high while a pulse is in flight.
    // A pulse is in flight from when it's latched in A until it's fully processed in B.

    // Let's define:
    // - a_latch: set on pulseA_i when !a_busy, cleared when ack_a_sync
    // - a_busy: a_latch
    // - b_sync: STAGES-stage sync of a_latch
    // - b_edge: rising edge of b_sync[STAGES-1]
    // - b_latch: set on b_edge, cleared when ack_b_sync
    // - pulseB_o: b_edge
    // - ack_b: b_latch
    // - ack_a_sync: STAGES-stage sync of ack_b
    // - ack_b_sync: STAGES-stage sync of a_latch (for clearing b_latch)
    // - busy_o: a_latch | b_latch

    // Wait, we need to be careful. Let's use a cleaner handshake.

    // Domain A:
    reg a_latch;
    wire a_busy;
    wire ack_a;

    // Domain B:
    reg [STAGES-1:0] b_sync;
    wire b_edge;
    reg b_latch;
    wire b_busy;
    wire ack_b;

    // Synchronizers
    reg [STAGES-1:0] ack_a_sync;
    reg [STAGES-1:0] a_latch_sync;

    // Domain A logic
    assign a_busy = a_latch;
    assign ack_a = ack_a_sync[STAGES-1];

    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a)
            a_latch <= 1'b0;
        else if (pulseA_i && !a_busy)
            a_latch <= 1'b1;
        else if (ack_a)
            a_latch <= 1'b0;
    end

    // Synchronize a_latch to domain B
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b)
            b_sync <= {STAGES{1'b0}};
        else
            b_sync <= {b_sync[STAGES-2:0], a_latch};
    end

    // Detect rising edge in domain B
    reg b_sync_prev;
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b)
            b_sync_prev <= 1'b0;
        else
            b_sync_prev <= b_sync[STAGES-1];
    end

    assign b_edge = b_sync[STAGES-1] & ~b_sync_prev;

    // Domain B logic
    assign b_busy = b_latch;
    assign ack_b = b_latch;

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b)
            b_latch <= 1'b0;
        else if (b_edge)
            b_latch <= 1'b1;
        else if (a_latch_sync[STAGES-1] == 1'b0)
            b_latch <= 1'b0;
    end

    // Synchronize ack_b to domain A
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a)
            ack_a_sync <= {STAGES{1'b0}};
        else
            ack_a_sync <= {ack_a_sync[STAGES-2:0], ack_b};
    end

    // Synchronize a_latch to domain B (for clearing b_latch)
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b)
            a_latch_sync <= {STAGES{1'b0}};
        else
            a_latch_sync <= {a_latch_sync[STAGES-2:0], a_latch};
    end

    assign pulseB_o = b_edge;
    assign busy_o = a_latch | b_latch;

endmodule
