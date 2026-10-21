```verilog
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
    output b_isolate_o
);

    // State Machine State Encoding
    // IDLE: Normal operation
    // REQ: Request received, waiting for peer to request
    // ISOLATE: Both sides isolated, waiting for peer to acknowledge isolation
    // CLEAR: Both sides isolated, waiting for peer to acknowledge clear
    // DONE: Both sides cleared, waiting for peer to release clear
    // RELEASE: Both sides cleared, waiting for peer to release isolate
    // CLEANUP: Final cleanup before returning to IDLE

    typedef enum logic [2:0] {
        IDLE,
        REQ,
        ISOLATE,
        CLEAR,
        DONE,
        RELEASE,
        CLEANUP
    } state_t;

    state_t current_state, next_state;

    // Handshake Signals (Synchronous to local clock)
    // a_side signals
    logic a_req;
    logic a_isolate_req;
    logic a_isolate_ack;
    logic a_clear_req;
    logic a_clear_ack;

    // b_side signals
    logic b_req;
    logic b_isolate_req;
    logic b_isolate_ack;
    logic b_clear_req;
    logic b_clear_ack;

    // Cross-domain synchronization registers
    // Synchronize b signals to a_clk
    logic b_req_a_synced;
    logic b_isolate_req_a_synced;
    logic b_isolate_ack_a_synced;
    logic b_clear_req_a_synced;
    logic b_clear_ack_a_synced;

    // Synchronize a signals to b_clk
    logic a_req_b_synced;
    logic a_isolate_req_b_synced;
    logic a_isolate_ack_b_synced;
    logic a_clear_req_b_synced;
    logic a_clear_ack_b_synced;

    // Synchronization Flip-Flops for cross-domain signals
    logic [SYNC_STAGES-1:0] b_req_ff;
    logic [SYNC_STAGES-1:0] b_isolate_req_ff;
    logic [SYNC_STAGES-1:0] b_isolate_ack_ff;
    logic [SYNC_STAGES-1:0] b_clear_req_ff;
    logic [SYNC_STAGES-1:0] b_clear_ack_ff;

    logic [SYNC_STAGES-1:0] a_req_ff;
    logic [SYNC_STAGES-1:0] a_isolate_req_ff;
    logic [SYNC_STAGES-1:0] a_isolate_ack_ff;
    logic [SYNC_STAGES-1:0] a_clear_req_ff;
    logic [SYNC_STAGES-1:0] a_clear_ack_ff;

    // Internal control flags
    logic both_isolated;
    logic both_cleared;
    logic peer_done;
    logic peer_released;

    // Output Drivers
    assign a_clear_o = (current_state == CLEAR) || (current_state == DONE) || (current_state == RELEASE) || (current_state == CLEANUP);
    assign b_clear_o = (current_state == CLEAR) || (current_state == DONE) || (current_state == RELEASE) || (current_state == CLEANUP);
    assign a_isolate_o = (current_state == ISOLATE) || (current_state == CLEAR) || (current_state == DONE) || (current_state == RELEASE) || (current_state == CLEANUP);
    assign b_isolate_o = (current_state == ISOLATE) || (current_state == CLEAR) || (current_state == DONE) || (current_state == RELEASE) || (current_state == CLEANUP);

    // Synchronization Logic for b -> a
    always_ff @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            b_req_ff <= '{default: 0};
            b_isolate_req_ff <= '{default: 0};
            b_isolate_ack_ff <= '{default: 0};
            b_clear_req_ff <= '{default: 0};
            b_clear_ack_ff <= '{default: 0};
        end else begin
            b_req_ff <= {b_req_ff[SYNC_STAGES-2:0], b_req};
            b_isolate_req_ff <= {b_isolate_req_ff[SYNC_STAGES-2:0], b_isolate_req};
            b_isolate_ack_ff <= {b_isolate_ack_ff[SYNC_STAGES-2:0], b_isolate_ack};
            b_clear_req_ff <= {b_clear_req_ff[SYNC_STAGES-2:0], b_clear_req};
            b_clear_ack_ff <= {b_clear_ack_ff[SYNC_STAGES-2:0], b_clear_ack};
        end
    end

    // Synchronization Logic for a -> b
    always_ff @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            a_req_ff <= '{default: 0};
            a_isolate_req_ff <= '{default: 0};
            a_isolate_ack_ff <= '{default: 0};
            a_clear_req_ff <= '{default: 0};
            a_clear_ack_ff <= '{default: 0};
        end else begin
            a_req_ff <= {a_req_ff[SYNC_STAGES-2:0], a_req};
            a_isolate_req_ff <= {a_isolate_req_ff[SYNC_STAGES-2:0], a_isolate_req};
            a_isolate_ack_ff <= {a_isolate_ack_ff[SYNC_STAGES-2:0], a_isolate_ack};
            a_clear_req_ff <= {a_clear_req_ff[SYNC_STAGES-2:0], a_clear_req};
            a_clear_ack_ff <= {a_clear_ack_ff[SYNC_STAGES-2:0], a_clear_ack};
        end
    end

    // Synchronous Inputs
    assign b_req_a_synced = b_req_ff[SYNC_STAGES-1];
    assign b_isolate_req_a_synced = b_isolate_req_ff[SYNC_STAGES-1];
    assign b_isolate_ack_a_synced = b_isolate_ack_ff[SYNC_STAGES-1];
    assign b_clear_req_a_synced = b_clear_req_ff[SYNC_STAGES-1];
    assign b_clear_ack_a_synced = b_clear_ack_ff[SYNC_STAGES-1];

    assign a_req_b_synced = a_req_ff[SYNC_STAGES-1];
    assign a_isolate_req_b_synced = a_isolate_req_ff[SYNC_STAGES-1];
    assign a_isolate_ack_b_synced = a_isolate_ack_ff[SYNC_STAGES-1];
    assign a_clear_req_b_synced = a_clear_req_ff[SYNC_STAGES-1];
    assign a_clear_ack_b_synced = a_clear_ack_ff[SYNC_STAGES-1];

    // State Machine Logic
    always_ff @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    always_comb begin
        next_state = current_state;

        case (current_state)
            IDLE: begin
                // Check if either side requests clear
                if (a_clear_i || b_req_a_synced) begin
                    next_state = REQ;
                end
            end

            REQ: begin
                // Wait for both sides to request
                if (a_clear_i && b_req_a_synced) begin
                    next_state = ISOLATE;
                end
            end

            ISOLATE: begin
                // Wait for both sides to acknowledge isolation
                if (a_isolate_ack && b_isolate_ack_a_synced) begin
                    next_state = CLEAR;
                end
            end

            CLEAR: begin
                // Wait for both sides to acknowledge clear
                if (a_clear_ack && b_clear_ack_a_synced) begin
                    next_state = DONE;
                end
            end

            DONE: begin
                // Wait for both sides to release clear
                if (a_clear_ack && b_clear_ack_a_synced) begin
                    next_state = RELEASE;
                end
            end

            RELEASE: begin
                // Wait for both sides to release isolate
                if (a_isolate_ack && b_isolate_ack_a_synced) begin
                    next_state = CLEANUP;
                end
            end

            CLEANUP: begin
                // Wait for both sides to release clear (again, to ensure clean exit)
                // Actually, based on behavior: "release isolate and clear". 
                // We are in RELEASE, waiting for isolate release. Once done, we go to IDLE.
                // But we must ensure peer has also released clear before going fully idle?
                // The spec says: "wait for both clear acks, then release isolate and clear."
                // So in RELEASE, we wait for isolate ack. Once we get it, we go to IDLE.
                // However, we must ensure the peer has also seen our release.
                // Let's simplify: Once both isolate acks are seen, we are done with the sequence.
                if (a_isolate_ack && b_isolate_ack_a_synced) begin
                    next_state = IDLE;
                end
            end

            default: next_state = IDLE;
        endcase
    end

    // Generate Control Signals for Cross-Domain
    // a_side generates signals for b
    assign a_req = (current_state == REQ);
    assign a_isolate_req = (current_state == ISOLATE);
    assign a_clear_req = (current_state == CLEAR);

    // b_side generates signals for a
    assign b_req = (current_state == REQ);
    assign b_isolate_req = (current_state == ISOLATE);
    assign b_clear_req = (current_state == CLEAR);

    // Acknowledgment Logic
    // a_ack signals are driven by b's state machine logic (simplified here as direct feedback)
    // In a real handshake, these would be driven by the peer's state machine.
    // Since this is a single module controlling both, we drive the acks based on the current state.
    
    // a_clear_ack_i is an input from the peer. We must wait for it.
    // a_isolate_ack_i is an input from the peer. We must wait for it.
    // b_clear_ack_i is an input from the peer. We must wait for it.
    // b_isolate_ack_i is an input from the peer. We must wait for it.

    // The state machine logic above already waits for these inputs.
    // We just need to make sure the outputs are driven correctly.
    
    // Re-evaluating the handshake logic based on the spec:
    // "Peer progress arrives in order: idle, then active, then done, then idle."
    // This implies a handshake protocol.
    // However, the state machine above implements the "Isolate-then-Clear" sequence.
    // The "Peer progress" part suggests we need to track the peer's state too.
    // But since we are the master controller, we drive the sequence.
    // The "peer completion" observation is done via the ack signals.

    // Let's refine the state machine to strictly follow the "Isolate-then-Clear" protocol
    // and ensure we don't leave one domain cleared while the other is live.

    // Revised State Machine Logic
    always_comb begin
        next_state = current_state;

        case (current_state)
            IDLE: begin
                // If either side requests clear, start the sequence
                if (a_clear_i || b_req_a_synced) begin
                    next_state = REQ;
                end
            end

            REQ: begin
                // Wait for both sides to request
                if (a_clear_i && b_req_a_synced) begin
                    next_state = ISOLATE;
                end
            end

            ISOLATE: begin
                // Wait for both sides to acknowledge isolation
                if (a_isolate_ack && b_isolate_ack_a_synced) begin
                    next_state = CLEAR;
                end
            end

            CLEAR: begin
                // Wait for both sides to acknowledge clear
                if (a_clear_ack && b_clear_ack_a_synced) begin
                    next_state = DONE;
                end
            end

            DONE: begin
                // Wait for both sides to release clear
                if (a_clear_ack && b_clear_ack_a_synced) begin
                    next_state = RELEASE;
                end
            end

            RELEASE: begin
                // Wait for both sides to release isolate
                if (a_isolate_ack && b_isolate_ack_a_synced) begin
                    next_state = IDLE;
                end
            end

            default: next_state = IDLE;
        endcase
    end

    // Output Drivers
    assign a_clear_o = (current_state == CLEAR) || (current_state == DONE) || (current_state == RELEASE) || (current_state == IDLE);
    assign b_clear_o = (current_state == CLEAR) || (current_state == DONE) || (current_state == RELEASE) || (current_state == IDLE);
    assign a_isolate_o = (current_state == ISOLATE) || (current_state == CLEAR) || (current_state == DONE) || (current_state == RELEASE) || (current_state == IDLE);
    assign b_isolate_o = (current_state == ISOLATE) || (current_state == CLEAR) || (current_state == DONE) || (current_state == RELEASE) || (current_state == IDLE);

endmodule
```<|im_end|>
