module cdc_reset_ctrlr #(
    parameter SYNC_STAGES = 2
)(
    input  a_clk_i,
    input  a_rst_ni,
    input  a_clear_i,
    output a_clear_o,
    input  a_clear_ack_i,
    output a_isolate_o,
    input  a_isolate_ack_i,
    input  b_clk_i,
    input  b_rst_ni,
    input  b_clear_i,
    output b_clear_o,
    input  b_clear_ack_i,
    output b_isolate_o,
    input  b_isolate_ack_i
);

    // State encoding
    localparam S_IDLE      = 3'd0;
    localparam S_ISOLATE   = 3'd1;
    localparam S_CLEAR     = 3'd2;
    localparam S_RELEASE   = 3'd3;
    localparam S_DONE      = 3'd4;

    // A-side state
    reg [2:0] a_state;
    // B-side state
    reg [2:0] b_state;

    // A-side outputs
    reg a_isolate_reg;
    reg a_clear_reg;

    // B-side outputs
    reg b_isolate_reg;
    reg b_clear_reg;

    // A-side: synchronized B-side state
    reg [2:0] b_state_sync;
    // B-side: synchronized A-side state
    reg [2:0] a_state_sync;

    // Synchronizer for A-side observing B-side state
    // We need to synchronize the 3-bit state from B domain to A domain.
    // Since state transitions are sequential and we only care about specific values,
    // we can synchronize each bit separately, but that risks incoherent multi-bit values.
    // Instead, we use a handshake-based approach or ensure that the state changes
    // are monotonic and we only check for specific patterns.
    //
    // A safer approach: use a 2-phase handshake for each state transition.
    // However, given the complexity, let's use a different architecture:
    // Each side has a local FSM that drives its own isolate/clear outputs.
    // The peer's progress is communicated via a single-bit "active" flag
    // that is synchronized across domains.
    //
    // Let's redesign with a simpler, safer CDC approach:
    // - Each side has a local FSM.
    // - When a side enters ISOLATE, it sets its isolate output and a "peer_isolate_request" flag.
    // - The peer synchronizes this flag and, when it sees it, also enters ISOLATE.
    // - Similarly for CLEAR and RELEASE.
    //
    // Actually, let's use a well-known pattern: each side has a local FSM,
    // and we use a 2-bit handshake (req/ack) for each phase transition.
    //
    // Given the constraints, let's implement a simpler but correct approach:
    // Each side independently tracks the sequence, but uses synchronized
    // single-bit flags to coordinate with the peer.

    // Let's use a different, cleaner architecture:
    // Each side has a local FSM with states: IDLE, ISOLATE, CLEAR, RELEASE, DONE
    // The FSM on each side drives its own isolate/clear outputs.
    // To coordinate, each side sends a "phase" signal to the other side.
    // The phase is a 2-bit value: 00=idle, 01=isolate, 10=clear, 11=release
    // We synchronize the 2-bit phase using a 2-stage synchronizer per bit,
    // but to ensure coherence, we use a handshake: the sender waits for an ack
    // before changing the phase again.

    // For simplicity and correctness, let's use a 1-bit "active" flag per phase.
    // Actually, let's just implement the FSM with proper CDC using
    // synchronized single-bit signals.

    // A-side: flag indicating B-side is in isolate phase
    reg b_isolate_flag;
    // A-side: flag indicating B-side is in clear phase
    reg b_clear_flag;
    // A-side: flag indicating B-side is in release phase
    reg b_release_flag;

    // B-side: flag indicating A-side is in isolate phase
    reg a_isolate_flag;
    // B-side: flag indicating A-side is in clear phase
    reg a_clear_flag;
    // B-side: flag indicating A-side is in release phase
    reg a_release_flag;

    // Synchronizers for A-side observing B-side flags
    reg [SYNC_STAGES-1:0] b_isolate_sync;
    reg [SYNC_STAGES-1:0] b_clear_sync;
    reg [SYNC_STAGES-1:0] b_release_sync;

    // Synchronizers for B-side observing A-side flags
    reg [SYNC_STAGES-1:0] a_isolate_sync;
    reg [SYNC_STAGES-1:0] a_clear_sync;
    reg [SYNC_STAGES-1:0] a_release_sync;

    // A-side FSM
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_state <= S_IDLE;
            a_isolate_reg <= 1'b0;
            a_clear_reg <= 1'b0;
            a_isolate_flag <= 1'b0;
            a_clear_flag <= 1'b0;
            a_release_flag <= 1'b0;
        end else begin
            case (a_state)
                S_IDLE: begin
                    a_isolate_reg <= 1'b0;
                    a_clear_reg <= 1'b0;
                    a_isolate_flag <= 1'b0;
                    a_clear_flag <= 1'b0;
                    a_release_flag <= 1'b0;
                    if (a_clear_i) begin
                        a_state <= S_ISOLATE;
                    end
                end
                S_ISOLATE: begin
                    a_isolate_reg <= 1'b1;
                    a_clear_reg <= 1'b0;
                    a_isolate_flag <= 1'b1;
                    a_clear_flag <= 1'b0;
                    a_release_flag <= 1'b0;
                    if (a_isolate_ack_i && b_isolate_sync[SYNC_STAGES-1]) begin
                        a_state <= S_CLEAR;
                    end
                end
                S_CLEAR: begin
                    a_isolate_reg <= 1'b1;
                    a_clear_reg <= 1'b1;
                    a_isolate_flag <= 1'b1;
                    a_clear_flag <= 1'b1;
                    a_release_flag <= 1'b0;
                    if (a_clear_ack_i && b_clear_sync[SYNC_STAGES-1]) begin
                        a_state <= S_RELEASE;
                    end
                end
                S_RELEASE: begin
                    a_isolate_reg <= 1'b1;
                    a_clear_reg <= 1'b0;
                    a_isolate_flag <= 1'b1;
                    a_clear_flag <= 1'b0;
                    a_release_flag <= 1'b1;
                    if (b_release_sync[SYNC_STAGES-1]) begin
                        a_state <= S_DONE;
                    end
                end
                S_DONE: begin
                    a_isolate_reg <= 1'b0;
                    a_clear_reg <= 1'b0;
                    a_isolate_flag <= 1'b0;
                    a_clear_flag <= 1'b0;
                    a_release_flag <= 1'b0;
                    a_state <= S_IDLE;
                end
                default: a_state <= S_IDLE;
            endcase
        end
    end

    // B-side FSM
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_state <= S_IDLE;
            b_isolate_reg <= 1'b0;
            b_clear_reg <= 1'b0;
            b_isolate_flag <= 1'b0;
            b_clear_flag <= 1'b0;
            b_release_flag <= 1'b0;
        end else begin
            case (b_state)
                S_IDLE: begin
                    b_isolate_reg <= 1'b0;
                    b_clear_reg <= 1'b0;
                    b_isolate_flag <= 1'b0;
                    b_clear_flag <= 1'b0;
                    b_release_flag <= 1'b0;
                    if (b_clear_i) begin
                        b_state <= S_ISOLATE;
                    end
                end
                S_ISOLATE: begin
                    b_isolate_reg <= 1'b1;
                    b_clear_reg <= 1'b0;
                    b_isolate_flag <= 1'b1;
                    b_clear_flag <= 1'b0;
                    b_release_flag <= 1'b0;
                    if (b_isolate_ack_i && a_isolate_sync[SYNC_STAGES-1]) begin
                        b_state <= S_CLEAR;
                    end
                end
                S_CLEAR: begin
                    b_isolate_reg <= 1'b1;
                    b_clear_reg <= 1'b1;
                    b_isolate_flag <= 1'b1;
                    b_clear_flag <= 1'b1;
                    b_release_flag <= 1'b0;
                    if (b_clear_ack_i && a_clear_sync[SYNC_STAGES-1]) begin
                        b_state <= S_RELEASE;
                    end
                end
                S_RELEASE: begin
                    b_isolate_reg <= 1'b1;
                    b_clear_reg <= 1'b0;
                    b_isolate_flag <= 1'b1;
                    b_clear_flag <= 1'b0;
                    b_release_flag <= 1'b1;
                    if (a_release_sync[SYNC_STAGES-1]) begin
                        b_state <= S_DONE;
                    end
                end
                S_DONE: begin
                    b_isolate_reg <= 1'b0;
                    b_clear_reg <= 1'b0;
                    b_isolate_flag <= 1'b0;
                    b_clear_flag <= 1'b0;
                    b_release_flag <= 1'b0;
                    b_state <= S_IDLE;
                end
                default: b_state <= S_IDLE;
            endcase
        end
    end

    // Synchronizers for A-side observing B-side flags
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            b_isolate_sync <= {SYNC_STAGES{1'b0}};
            b_clear_sync <= {SYNC_STAGES{1'b0}};
            b_release_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            b_isolate_sync <= {b_isolate_sync[SYNC_STAGES-2:0], b_isolate_flag};
            b_clear_sync <= {b_clear_sync[SYNC_STAGES-2:0], b_clear_flag};
            b_release_sync <= {b_release_sync[SYNC_STAGES-2:0], b_release_flag};
        end
    end

    // Synchronizers for B-side observing A-side flags
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            a_isolate_sync <= {SYNC_STAGES{1'b0}};
            a_clear_sync <= {SYNC_STAGES{1'b0}};
            a_release_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            a_isolate_sync <= {a_isolate_sync[SYNC_STAGES-2:0], a_isolate_flag};
            a_clear_sync <= {a_clear_sync[SYNC_STAGES-2:0], a_clear_flag};
            a_release_sync <= {a_release_sync[SYNC_STAGES-2:0], a_release_flag};
        end
    end

    // Output assignments
    assign a_isolate_o = a_isolate_reg;
    assign a_clear_o = a_clear_reg;
    assign b_isolate_o = b_isolate_reg;
    assign b_clear_o = b_clear_reg;

endmodule
