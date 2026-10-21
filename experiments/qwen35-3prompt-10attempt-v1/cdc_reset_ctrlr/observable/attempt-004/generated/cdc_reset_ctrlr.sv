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
    output b_isolate_o,
    input  b_isolate_ack_i
);

    // ------------------------------------------------------------------
    // CDC Registers for Domain A signals seen in Domain B
    // ------------------------------------------------------------------
    reg [SYNC_STAGES-1:0] a_clear_synced_b;
    reg [SYNC_STAGES-1:0] a_clear_ack_synced_b;
    reg [SYNC_STAGES-1:0] a_isolate_synced_b;
    reg [SYNC_STAGES-1:0] a_isolate_ack_synced_b;

    // ------------------------------------------------------------------
    // CDC Registers for Domain B signals seen in Domain A
    // ------------------------------------------------------------------
    reg [SYNC_STAGES-1:0] b_clear_synced_a;
    reg [SYNC_STAGES-1:0] b_clear_ack_synced_a;
    reg [SYNC_STAGES-1:0] b_isolate_synced_a;
    reg [SYNC_STAGES-1:0] b_isolate_ack_synced_a;

    // ------------------------------------------------------------------
    // State Machine State Encoding
    // ------------------------------------------------------------------
    // IDLE: No requests pending, system ready
    // REQ_A: Domain A requested Clear, waiting for Isolate
    // REQ_B: Domain B requested Clear, waiting for Isolate
    // ISOLATING: Both sides isolated, waiting for Clear Ack from both
    // CLEARING_A: Clearing A, waiting for A Ack
    // CLEARING_B: Clearing B, waiting for B Ack
    // DONE: Clear complete, returning to IDLE

    localparam IDLE = 3'b000;
    localparam REQ_A = 3'b001;
    localparam REQ_B = 3'b010;
    localparam ISOLATING = 3'b011;
    localparam CLEARING_A = 3'b100;
    localparam CLEARING_B = 3'b101;
    localparam DONE = 3'b110;

    reg [2:0] state, next_state;

    // ------------------------------------------------------------------
    // CDC Logic Generation (Synchronous to respective clocks)
    // ------------------------------------------------------------------
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_clear_synced_b <= {SYNC_STAGES{1'b0}};
            a_clear_ack_synced_b <= {SYNC_STAGES{1'b0}};
            a_isolate_synced_b <= {SYNC_STAGES{1'b0}};
            a_isolate_ack_synced_b <= {SYNC_STAGES{1'b0}};
        end else begin
            a_clear_synced_b <= {a_clear_synced_b[SYNC_STAGES-2:0], a_clear_i};
            a_clear_ack_synced_b <= {a_clear_ack_synced_b[SYNC_STAGES-2:0], a_clear_ack_i};
            a_isolate_synced_b <= {a_isolate_synced_b[SYNC_STAGES-2:0], a_isolate_i};
            a_isolate_ack_synced_b <= {a_isolate_ack_synced_b[SYNC_STAGES-2:0], a_isolate_ack_i};
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_clear_synced_a <= {SYNC_STAGES{1'b0}};
            b_clear_ack_synced_a <= {SYNC_STAGES{1'b0}};
            b_isolate_synced_a <= {SYNC_STAGES{1'b0}};
            b_isolate_ack_synced_a <= {SYNC_STAGES{1'b0}};
        end else begin
            b_clear_synced_a <= {b_clear_synced_a[SYNC_STAGES-2:0], b_clear_i};
            b_clear_ack_synced_a <= {b_clear_ack_synced_a[SYNC_STAGES-2:0], b_clear_ack_i};
            b_isolate_synced_a <= {b_isolate_synced_a[SYNC_STAGES-2:0], b_isolate_i};
            b_isolate_ack_synced_a <= {b_isolate_ack_synced_a[SYNC_STAGES-2:0], b_isolate_ack_i};
        end
    end

    // ------------------------------------------------------------------
    // State Machine Logic
    // ------------------------------------------------------------------
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni)
            next_state <= IDLE;
        else
            next_state = state; // Default hold

        case (state)
            IDLE: begin
                // Check if either side has requested a clear
                if (b_clear_synced_a[SYNC_STAGES-1])
                    next_state = REQ_B;
                else if (a_clear_synced_b[SYNC_STAGES-1])
                    next_state = REQ_A;
                else
                    next_state = IDLE;
            end

            REQ_A: begin
                // A requested clear. We must isolate both domains first.
                // We assert isolate on A side (local) and wait for B side to acknowledge isolation.
                // Note: The problem says "isolate both sides before clearing".
                // Since we are in REQ_A, A has already requested clear.
                // We need to ensure B is isolated too.
                
                // Logic: Assert A Isolate. Wait for A Isolate Ack.
                // Simultaneously, we need to ensure B Isolate is asserted and acked.
                // However, the handshake protocol implies we drive the signal and wait for ack.
                // Since B is in a different domain, we drive B_isolate_o based on our state.
                
                // Step 1: Assert Isolate on both sides.
                // We assert a_isolate_o immediately.
                // We assert b_isolate_o immediately.
                // We wait for both acks.
                
                // To simplify the handshake flow described:
                // "wait for both acknowledgments at each step before releasing them"
                // "Peer progress arrives in order: idle, then active, then done, then idle."
                // This implies a strict sequence.
                
                // Let's refine the state machine to match the strict "Isolate -> Clear" flow.
                // Current State: REQ_A (A wants clear).
                // Action: Assert Isolate on A and B.
                // Wait for: A_Isolate_Ack and B_Isolate_Ack.
                // Next State: ISOLATING (Both isolated, now wait for Clear Ack).
                
                // Actually, the prompt says: "When either side requests a clear, isolate both sides before clearing either of them"
                // So from REQ_A or REQ_B, we go to a state where we assert isolates.
                
                // Let's restructure slightly for clarity in the FSM:
                // REQ_A: A requested. We assert A_Isolate and B_Isolate.
                // We wait for both acks.
                // Once both acks are seen, we move to ISOLATING (ready to clear).
                
                // But wait, the prompt says "wait for both acknowledgments at each step".
                // Step 1: Isolate.
                // Step 2: Clear.
                
                // Let's assume the CDC syncs the *request* and the *ack*.
                // We drive the outputs (isolate_o, clear_o) based on our internal state.
                // We sample the inputs (isolate_ack_i, clear_ack_i) via CDC.
                
                // In REQ_A:
                // We assert a_isolate_o and b_isolate_o.
                // We wait until (a_isolate_ack_synced_b[SYNC_STAGES-1] && b_isolate_ack_synced_a[SYNC_STAGES-1]).
                // Then we go to ISOLATING.
                
                if (a_isolate_synced_b[SYNC_STAGES-1] && b_isolate_ack_synced_a[SYNC_STAGES-1])
                    next_state = ISOLATING;
                else
                    next_state = REQ_A;
            end

            REQ_B: begin
                // Symmetric to REQ_A
                if (a_isolate_synced_b[SYNC_STAGES-1] && b_isolate_ack_synced_a[SYNC_STAGES-1])
                    next_state = ISOLATING;
                else
                    next_state = REQ_B;
            end

            ISOLATING: begin
                // Both sides are isolated. Now we can start clearing.
                // "wait for both acknowledgments at each step before releasing them"
                // We need to clear A and B.
                // Do we clear them simultaneously or sequentially?
                // "Do not release isolate or clear before the peer completion has been observed."
                // This suggests we might need to clear one, wait for ack, then clear the other?
                // OR, we assert clear on both, and wait for BOTH acks before releasing isolate.
                // Given "isolate both sides before clearing either", and "wait for both acks",
                // it implies a parallel clear assertion, but we must wait for both acks to release isolate.
                
                // However, if we clear both simultaneously, and one fails or is slow, we are stuck.
                // But the protocol says "Peer progress arrives in order: idle, then active, then done".
                // This usually implies a handshake per domain.
                
                // Let's interpret "wait for both acknowledgments at each step" as:
                // Assert Clear on both. Wait for Clear Ack on both.
                // Once both acks are received, release isolate on both.
                
                // But what if we clear A, wait for A ack, then clear B?
                // The prompt says "before clearing either of them; wait for both acknowledgments".
                // This phrasing is slightly ambiguous. Does it mean "Wait for both acks before releasing isolate"?
                // Yes, "before releasing them" refers to the isolate.
                
                // So: Assert Clear A, Clear B. Wait for Ack A, Ack B. Then Release Isolate A, Isolate B.
                
                // Check if both clear acks are ready.
                if (a_clear_ack_synced_b[SYNC_STAGES-1] && b_clear_ack_synced_a[SYNC_STAGES-1])
                    next_state = DONE;
                else
                    next_state = ISOLATING;
            end

            CLEARING_A: begin
                // This state seems redundant if we clear both in ISOLATING.
                // Let's reconsider the "Peer progress" constraint.
                // "Peer progress arrives in order: idle, then active, then done, then idle."
                // This might imply that we cannot clear A until B is done clearing?
                // No, that would be serial clearing.
                // "Do not release isolate or clear before the peer completion has been observed."
                // This likely means: You cannot release the Isolate signal until you have seen the peer's Clear Ack.
                // It does NOT necessarily mean you must clear serially.
                
                // Let's stick to the parallel clear approach in ISOLATING, but ensure the logic handles the "peer completion" constraint.
                // If we clear both, and wait for both acks, we satisfy "wait for both acknowledgments".
                // And we only release isolate after both acks, satisfying "before releasing them".
                
                // Is there a case where we clear one, wait, then clear the other?
                // If the system requires strict ordering of clear events across domains, we might need serial clearing.
                // However, standard reset controllers often clear in parallel once isolated.
                // Let's assume parallel clear is acceptable unless "peer completion" implies serial dependency.
                // "Peer progress arrives in order... Do not release isolate... before peer completion".
                // This confirms: Release Isolate ONLY after Peer Clear Ack.
                // It does not explicitly forbid clearing both at once.
                
                // BUT, looking at the state machine flow:
                // If we are in ISOLATING, we assert clear_o.
                // We wait for acks.
                // If we get both acks, we go to DONE.
                // In DONE, we de-assert clear_o and isolate_o.
                
                // Wait, the prompt says "wait for both acknowledgments at each step".
                // Step 1: Isolate. (Wait for Isolate Ack).
                // Step 2: Clear. (Wait for Clear Ack).
                
                // My current ISOLATING state does exactly this.
                // However, I need to make sure I don't get stuck if one ack comes late.
                // The state machine loops on ISOLATING until both acks are high.
                
                // One edge case: What if the request comes in while the other side is already clearing?
                // The state machine handles this: if B is clearing, B_clear_synced_a will be 1.
                // If A requests, we go to REQ_A. We assert Isolate. We wait for Isolate Ack.
                // Then we go to ISOLATING. We assert Clear A and Clear B (if not already asserted).
                // Wait for Clear Ack A and Clear Ack B.
                
                // There is a potential race: If we are in ISOLATING, and we assert Clear A and Clear B.
                // If B was already clearing (from a previous request), b_clear_o is already low.
                // We just need to wait for the ack.
                // The state machine logic holds.
                
                // Wait, I need to check the "Peer progress" constraint again.
                // "Do not release isolate or clear before the peer completion has been observed."
                // This implies that if I am clearing A, I must wait for B's completion before I can release A's isolate?
                // Or does it mean I cannot release the Isolate signal (which protects the clear) until the peer is done?
                // Yes, that's the standard interpretation.
                
                // So the logic in ISOLATING is correct: Assert Clear, Wait for Both Ack, Then Release Isolate.
                
                // One detail: "Peer progress arrives in order: idle, then active, then done, then idle."
                // This describes the handshake sequence.
                // Idle -> Active (Request) -> Done (Ack) -> Idle.
                // My CDC logic captures the 'Active' (Request) and 'Done' (Ack) bits.
                
                // Let's verify the output logic.
                // In ISOLATING, we assert clear_o.
                // In DONE, we de-assert clear_o and isolate_o.
                
                // Wait, what if the request is cancelled?
                // The problem doesn't specify a cancel mechanism, just "requests a clear".
                // We assume the request is valid until the operation completes.
                
                // One refinement: The state machine should probably assert the outputs in the transition or the current state.
                // We will drive outputs based on the current state.
                
                // Re-evaluating the "CLEARING_A" and "CLEARING_B" states.
                // If I remove them and just do everything in ISOLATING, is it sufficient?
                // Yes, if we assert clear_o in ISOLATING and keep it asserted until DONE.
                
                // However, to be safe and explicit about the "step" concept:
                // Step 1: Isolate. (State: REQ -> ISOLATING).
                // Step 2: Clear. (State: ISOLATING -> DONE).
                // This matches the "wait for both acknowledgments at each step" requirement.
                
                // So, in ISOLATING:
                // 1. Assert a_isolate_o, b_isolate_o.
                // 2. Assert a_clear_o, b_clear_o.
                // 3. Wait for a_clear_ack_synced_b[SYNC_STAGES-1] && b_clear_ack_synced_a[SYNC_STAGES-1].
                // 4. If true, next_state = DONE.
                
                // In DONE:
                // 1. De-assert a_isolate_o, b_isolate_o.
                // 2. De-assert a_clear_o, b_clear_o.
                // 3. next_state = IDLE.
                
                // This seems robust.
                
                if (a_clear_ack_synced_b[SYNC_STAGES-1] && b_clear_ack_synced_a[SYNC_STAGES-1])
                    next_state = DONE;
                else
                    next_state = ISOLATING;
            end

            DONE: begin
                // Release everything
                next_state = IDLE;
            end

            default:
                next_state = IDLE;
        endcase
    end

    // ------------------------------------------------------------------
    // Output Logic
    // ------------------------------------------------------------------
    // Active Low signals
    assign a_isolate_o = (state == ISOLATING || state == DONE) ? 1'b0 : 1'b1;
    assign b_isolate_o = (state == ISOLATING || state == DONE) ? 1'b0 : 1'b1;
    
    assign a_clear_o = (state == ISOLATING || state == DONE) ? 1'b0 : 1'b1;
    assign b_clear_o = (state == ISOLATING || state == DONE) ? 1'b0 : 1'b1;

endmodule
```<|im_end|>
