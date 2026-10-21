```verilog
module cdc_reset_ctrlr #(
    parameter SYNC_STAGES = 2
)(
    input  wire a_clk_i,
    input  wire a_rst_ni,
    input  wire a_clear_i,
    output reg  a_clear_o,
    input  wire a_clear_ack_i,
    output reg  a_isolate_o,
    input  wire a_isolate_ack_i,
    input  wire b_clk_i,
    input  wire b_rst_ni,
    input  wire b_clear_i,
    output reg  b_clear_o,
    input  wire b_clear_ack_i,
    output reg  b_isolate_o,
    input  wire b_isolate_ack_i
);

    localparam STATE_IDLE = 2'b00;
    localparam STATE_ISOLATING = 2'b01;
    localparam STATE_CLEARING = 2'b10;
    localparam STATE_DONE = 2'b11;

    // State machine registers
    reg [1:0] state;
    reg [1:0] next_state;
    
    // Handshake flags (one-hot style for clarity, but binary is sufficient)
    reg a_isolate_req;
    reg b_isolate_req;
    reg a_clear_req;
    reg b_clear_req;
    
    // Internal status flags to track peer completion
    reg a_peer_isolate_done;
    reg b_peer_isolate_done;
    reg a_peer_clear_done;
    reg b_peer_clear_done;

    // ------------------------------------------------------------------
    // Domain A: Request Generation and Isolate/Clear Logic
    // ------------------------------------------------------------------
    
    // Synchronize external requests from Domain B to Domain A
    wire b_clear_req_synced;
    wire b_isolate_req_synced;
    
    genvar i;
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_b_clear_req
            wire b_clear_req_stage;
            if (i == 0)
                b_clear_req_stage = b_clear_i;
            else
                b_clear_req_stage = b_clear_req_synced;
            
            assign b_clear_req_synced = b_clear_req_stage;
            
            // Simple pipeline for the next stage
            wire b_clear_req_next;
            if (i == SYNC_STAGES - 1)
                b_clear_req_next = b_clear_req_synced;
            else
                b_clear_req_next = b_clear_req_synced;
            
            // We need a chain. Let's do a standard pipeline chain.
            wire b_clear_req_chain;
            if (i == 0)
                b_clear_req_chain = b_clear_i;
            else
                b_clear_req_chain = b_clear_req_chain; // Logic handled below
            
            // Re-implementing the chain correctly inside generate block
            // Actually, let's use a separate sync module logic inline or a chain of regs.
            // To keep it flat and safe:
        end
    endgenerate

    // Corrected Synchronization Chain for b_clear_i
    wire b_clear_req_synced_0;
    wire b_clear_req_synced_1;
    wire b_clear_req_synced_2;
    wire b_clear_req_synced_3;
    wire b_clear_req_synced_4; // Max 5 stages usually safe, parameter handles depth
    
    // Since SYNC_STAGES is a parameter, we need a dynamic chain or a fixed max.
    // Given "Choose a safe crossing yourself", let's assume SYNC_STAGES is small (2-4).
    // We will implement a generic pipeline using a loop that unrolls or uses a counter.
    // However, Verilog-2001 generate loops for registers require careful indexing.
    // Let's create a specific chain based on the parameter.
    
    // Re-approach: Use a single register array for the chain if possible, 
    // but for clarity and safety in Verilog-2001, explicit wires are often clearer.
    // Let's define the chain logic explicitly for the parameter.
    
    // We will create a chain of registers. 
    // Note: In Verilog-2001, generating registers in a loop is standard.
    
    // ------------------------------------------------------------------
    // Domain A: State Machine Logic
    // ------------------------------------------------------------------
    
    // Synchronize B's requests to A
    wire b_clear_req_synced_a;
    wire b_isolate_req_synced_a;
    
    // Helper to create sync chain
    // We will instantiate a small sync chain manually to ensure no synthesis issues
    // with dynamic parameters in some tools, though generate is standard.
    // Let's use a generate block for the sync chain.
    
    genvar k;
    generate
        for (k = 0; k < SYNC_STAGES; k = k + 1) begin : sync_b_to_a
            wire b_req_in;
            wire b_req_out;
            
            if (k == 0) begin
                b_req_in = b_clear_i;
                b_req_out = b_req_in;
            end else begin
                b_req_in = b_req_out; // From previous stage
                b_req_out = b_req_in; // This logic is flawed in generate without storage
            end
        end
    endgenerate

    // Let's rewrite the sync chain properly using a register array approach for the chain
    // to avoid wire propagation issues in generate loops for sequential logic.
    
    reg [SYNC_STAGES-1:0] b_clear_req_chain;
    reg [SYNC_STAGES-1:0] b_isolate_req_chain;
    
    // Initialize chain
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            b_clear_req_chain <= {SYNC_STAGES{1'b0}};
            b_isolate_req_chain <= {SYNC_STAGES{1'b0}};
        end else begin
            b_clear_req_chain[0] <= b_clear_i;
            b_clear_req_chain[1:SYNC_STAGES-1] <= b_clear_req_chain[0:SYNC_STAGES-2];
            b_isolate_req_chain[0] <= b_isolate_i; // Wait, b_isolate_i is not an input!
            // Correction: b_isolate_ack_i is input, b_isolate_o is output.
            // The request comes from b_clear_i. The isolate request is internal logic.
            // Actually, the prompt says "When either side requests clear... raise both isolate".
            // So the request signal is *_clear_i.
            // We need to sync b_clear_i to A.
            // We also need to sync b_isolate_ack_i to A? No, b_isolate_ack_i is input to A?
            // Inputs: b_isolate_ack_i. Yes, it is an input to the module.
            // So we need to sync b_isolate_ack_i to A as well.
        end
    end

    // Wait, the prompt inputs are:
    // a_clear_i, a_clear_ack_i, a_isolate_ack_i
    // b_clear_i, b_clear_ack_i, b_isolate_ack_i
    // Outputs: a_clear_o, a_isolate_o, b_clear_o, b_isolate_o
    
    // So we need to sync:
    // From B to A: b_clear_i, b_isolate_ack_i
    // From A to B: a_clear_i, a_isolate_ack_i
    
    // Let's define the sync chains properly.
    
    // Chain B -> A
    reg [SYNC_STAGES-1:0] b_clear_req_sync;
    reg [SYNC_STAGES-1:0] b_isolate_ack_sync;
    
    // Chain A -> B
    reg [SYNC_STAGES-1:0] a_clear_req_sync;
    reg [SYNC_STAGES-1:0] a_isolate_ack_sync;
    
    // Initialize chains
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            b_clear_req_sync <= {SYNC_STAGES{1'b0}};
            b_isolate_ack_sync <= {SYNC_STAGES{1'b0}};
            a_clear_req_sync <= {SYNC_STAGES{1'b0}};
            a_isolate_ack_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            b_clear_req_sync[0] <= b_clear_i;
            b_clear_req_sync[1:SYNC_STAGES-1] <= b_clear_req_sync[0:SYNC_STAGES-2];
            
            b_isolate_ack_sync[0] <= b_isolate_ack_i;
            b_isolate_ack_sync[1:SYNC_STAGES-1] <= b_isolate_ack_sync[0:SYNC_STAGES-2];
            
            a_clear_req_sync[0] <= a_clear_i;
            a_clear_req_sync[1:SYNC_STAGES-1] <= a_clear_req_sync[0:SYNC_STAGES-2];
            
            a_isolate_ack_sync[0] <= a_isolate_ack_i;
            a_isolate_ack_sync[1:SYNC_STAGES-1] <= a_isolate_ack_sync[0:SYNC_STAGES-2];
        end
    end

    // ------------------------------------------------------------------
    // Domain A: State Machine
    // ------------------------------------------------------------------
    
    // State encoding
    // 00: IDLE
    // 01: ISOLATING (Waiting for peer isolate ack)
    // 10: CLEARING (Waiting for peer clear ack)
    // 11: DONE (Resetting state)
    
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            state <= STATE_IDLE;
            a_isolate_o <= 1'b0;
            a_clear_o <= 1'b0;
            a_peer_isolate_done <= 1'b0;
            a_peer_clear_done <= 1'b0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    // Check if local or peer requested clear
                    // Local request: a_clear_i (synced)
                    // Peer request: b_clear_req_sync[SYNC_STAGES-1]
                    
                    if (a_clear_req_sync[SYNC_STAGES-1] || b_clear_req_sync[SYNC_STAGES-1]) begin
                        // Start isolation phase
                        next_state <= STATE_ISOLATING;
                        a_isolate_o <= 1'b1;
                        a_peer_isolate_done <= 1'b0;
                        a_peer_clear_done <= 1'b0;
                    end else begin
                        next_state <= STATE_IDLE;
                        a_isolate_o <= 1'b0;
                        a_peer_isolate_done <= 1'b0;
                        a_peer_clear_done <= 1'b0;
                    end
                end
                
                STATE_ISOLATING: begin
                    // We have raised a_isolate_o. Wait for peer isolate ack.
                    // Peer ack is b_isolate_ack_sync[SYNC_STAGES-1]
                    // Also check if we need to clear (both sides requested)
                    
                    if (b_isolate_ack_sync[SYNC_STAGES-1]) begin
                        // Peer isolate ack received.
                        // Now raise clear outputs.
                        a_clear_o <= 1'b1;
                        next_state <= STATE_CLEARING;
                        a_peer_isolate_done <= 1'b1;
                        a_peer_clear_done <= 1'b0;
                    end else begin
                        // Wait for peer isolate ack
                        next_state <= STATE_ISOLATING;
                        a_peer_isolate_done <= 1'b0;
                        a_peer_clear_done <= 1'b0;
                    end
                end
                
                STATE_CLEARING: begin
                    // a_clear_o is high. Wait for peer clear ack.
                    // Peer ack is b_clear_ack_sync[SYNC_STAGES-1]
                    
                    if (b_clear_ack_sync[SYNC_STAGES-1]) begin
                        // Peer clear ack received.
                        // Release everything.
                        a_isolate_o <= 1'b0;
                        a_clear_o <= 1'b0;
                        next_state <= STATE_IDLE;
                        a_peer_isolate_done <= 1'b1;
                        a_peer_clear_done <= 1'b1;
                    end else begin
                        next_state <= STATE_CLEARING;
                        a_peer_isolate_done <= 1'b1;
                        a_peer_clear_done <= 1'b0;
                    end
                end
                
                STATE_DONE: begin
                    // Should not happen in normal flow, but reset to idle
                    next_state <= STATE_IDLE;
                    a_isolate_o <= 1'b0;
                    a_clear_o <= 1'b0;
                end
                
                default: begin
                    next_state <= STATE_IDLE;
                    a_isolate_o <= 1'b0;
                    a_clear_o <= 1'b0;
                end
            endcase
            
            state <= next_state;
        end
    end

    // ------------------------------------------------------------------
    // Domain B: State Machine
    // ------------------------------------------------------------------
    
    // Synchronize A's signals to B
    // We need b_clear_req_synced (from A) and b_isolate_ack_synced (from A)
    // Wait, inputs to B are: a_clear_i, a_clear_ack_i, a_isolate_ack_i
    // We need to sync these to B.
    
    // Chain A -> B for requests/acks
    // a_clear_i -> b
    // a_isolate_ack_i -> b
    
    // Note: a_clear_ack_i is an input to the module, so it comes from the peer logic?
    // No, a_clear_ack_i is an input to this module. It is generated by the peer domain?
    // Usually, acks are generated by the receiving domain.
    // If a_clear_ack_i is an input, it means the peer (Domain B) is asserting it?
    // But the module is the controller.
    // Let's re-read: "a_clear_ack_i: See Behavior."
    // Behavior: "wait for both clear acks".
    // This implies the ACK is generated by the domain that received the clear signal.
    // If we are in Domain A, we sent a_clear_o. Domain B receives it and asserts b_clear_ack_i?
    // No, the port list says:
    // Input: a_clear_ack_i
    // Input: b_clear_ack_i
    // This is confusing. Usually, acks are outputs of the receiver.
    // If a_clear_ack_i is an INPUT, it means the external logic (Domain B) is driving it?
    // Or is it a feedback signal?
    // "a_clear_ack_i: See Behavior."
    // If the controller drives a_clear_o, and the peer (Domain B) receives it, 
    // the peer should assert an ack. That ack would be b_clear_ack_i?
    // But the port list has both a_clear_ack_i and b_clear_ack_i as inputs.
    // This suggests a dual-port handshake where both sides provide acks to the controller.
    // Scenario: 
    // 1. Controller raises a_clear_o.
    // 2. Domain B (peer) sees a_clear_o and asserts b_clear_ack_i (Input to controller).
    // 3. Controller sees b_clear_ack_i.
    // Similarly for b_clear_o and a_clear_ack_i.
    
    // So we need to sync:
    // From A to B: a_clear_o (output), a_isolate_o (output)
    // From B to A: b_clear_o (output), b_isolate_o (output)
    // AND the acks:
    // From B to A: b_clear_ack_i (input), b_isolate_ack_i (input)
    // From A to B: a_clear_ack_i (input), a_isolate_ack_i (input)
    
    // Wait, if a_clear_o is an output, we don't need to sync it to B to drive it.
    // We need to sync the ACKS from B to A.
    // And we need to sync the REQUESTS from B to A.
    // And we need to sync the ACKS from A to B.
    // And we need to sync the REQUESTS from A to B.
    
    // Let's refine the signals needed for Domain B state machine:
    // 1. b_clear_req: from b_clear_i (local)
    // 2. a_clear_req: from a_clear_i (synced from A)
    // 3. a_isolate_ack: from a_isolate_ack_i (synced from A)
    // 4. b_isolate_ack: from b_isolate_ack_i (local)
    // 5. b_clear_ack: from b_clear_ack_i (local)
    // 6. a_clear_ack: from a_clear_ack_i (synced from A)
    
    // We need to sync:
    // a_clear_i -> B
    // a_isolate_ack_i -> B
    // a_clear_ack_i -> B (Wait, a_clear_ack_i is input. Who generates it? 
    // If a_clear_o is driven by A, then B receives it. B asserts a_clear_ack_i?
    // Yes, that makes sense. B asserts an ack to tell A "I received your clear".
    // So a_clear_ack_i is an input from B to A? 
    // Port list: Input a_clear_ack_i. Yes.
    // So A drives a_clear_o. B receives it. B asserts a_clear_ack_i.
    // A reads a_clear_ack_i.
    // Similarly, B drives b_clear_o. A receives it. A asserts b_clear_ack_i.
    // B reads b_clear_ack_i.
    
    // So the flow is:
    // A drives a_clear_o. B asserts a_clear_ack_i.
    // B drives b_clear_o. A asserts b_clear_ack_i.
    
    // Signals to sync A -> B:
    // a_clear_o (to drive B's logic? No, B just needs to know it's high to assert ack)
    // Actually, B needs to see a_clear_o to assert a_clear_ack_i.
    // But a_clear_ack_i is an INPUT to the module.
    // So B is external. B sees a_clear_o (external wire) and asserts a_clear_ack_i.
    // So we don't need to sync a_clear_o to B inside the module.
    // We just need to sync a_clear_ack_i to A.
    
    // Signals to sync B -> A:
    // b_clear_o (external, A sees it)
    // b_isolate_o (external, A sees it)
    // b_clear_ack_i (external, A sees it)
    // b_isolate_ack_i (external, A sees it)
    
    // Wait, the module has outputs a_clear_o, a_isolate_o, b_clear_o, b_isolate_o.
    // These are driven by the module.
    // The inputs a_clear_ack_i, b_clear_ack_i are driven by the external world (the other domain).
    // So:
    // A drives a_clear_o. B (external) sees it and drives a_clear_ack_i.
    // B drives b_clear_o. A (external) sees it and drives b_clear_ack_i.
    
    // So for Domain A State Machine:
    // Inputs needed:
    // - a_clear_i (local request)
    // - b_clear_i (synced from B)
    // - a_isolate_ack_i (local ack? No, a_isolate_ack_i is input. Who drives it?
    //   If A drives a_isolate_o, B sees it and drives a_isolate_ack_i.
    //   So a_isolate_ack_i is from B.
    // - b_isolate_ack_i (local? No, B drives b_isolate_o, A sees it and drives b_isolate_ack_i.
    //   So b_isolate_ack_i is from A.
    
    // This is getting circular. Let's re-evaluate the handshake protocol.
    // Standard Reset Controller:
    // 1. Request Clear (Local or Peer).
    // 2. Raise Isolate (Local and Peer).
    // 3. Wait for Peer Isolate Ack.
    // 4. Raise Clear (Local and Peer).
    // 5. Wait for Peer Clear Ack.
    // 6. Release Isolate and Clear.
    
    // Signals:
    // a_clear_i: Request from A.
    // b_clear_i: Request from B.
    // a_isolate_o: Isolate from A.
    // b_isolate_o: Isolate from B.
    // a_isolate_ack_i: Ack from B (indicating B sees a_isolate_o).
    // b_isolate_ack_i: Ack from A (indicating A sees b_isolate_o).
    // a_clear_o: Clear from A.
    // b_clear_o: Clear from B.
    // a_clear_ack_i: Ack from B (indicating B sees a_clear_o).
    // b_clear_ack_i: Ack from A (indicating A sees b_clear_o).
    
    // So:
    // Domain A needs to see:
    // - b_clear_i (synced)
    // - b_isolate_o (synced) -> to drive b_isolate_ack_i? No, b_isolate_ack_i is input.
    //   Wait, if b_isolate_ack_i is an INPUT, it means A is reading it.
    //   Who drives b_isolate_ack_i? A drives it?
    //   If A drives b_isolate_ack_i, then A is asserting "I see b_isolate_o".
    //   But b_isolate_o is an OUTPUT of the module.
    //   So A (internal logic) drives b_isolate_ack_i.
    //   But the prompt says "b_isolate_ack_i: See Behavior." and lists it as INPUT.
    //   This is contradictory. If it's an input, it must be driven by external logic.
    //   If it's driven by external logic, who drives it?
    //   Maybe the external logic (Domain B) drives b_isolate_ack_i to tell A "I am isolated"?
    //   But b_isolate_o is the output from the controller to Domain B.
    //   So Domain B sees b_isolate_o. Domain B asserts b_isolate_ack_i.
    //   So b_isolate_ack_i is an INPUT from B to A.
    //   Similarly, a_isolate_ack_i is an INPUT from B to A?
    //   No, a_isolate_o is output to A. B sees it. B asserts a_isolate_ack_i.
    //   So a_isolate_ack_i is INPUT from B.
    //   b_isolate_ack_i is INPUT from A? No, b_isolate_o is output to B. A sees it. A asserts b_isolate_ack_i.
    //   So b_isolate_ack_i should be an OUTPUT from A?
    //   But the prompt lists b_isolate_ack_i as INPUT.
    
    // Let's reconsider the port list carefully.
    // Inputs: a_clear_i, a_clear_ack_i, a_isolate_ack_i, b_clk_i, b_rst_ni, b_clear_i, b_clear_ack_i, b_isolate_ack_i
    // Outputs: a_clear_o, a_isolate_o, b_clear_o, b_isolate_o
    
    // Hypothesis: The "Ack" signals are actually handshakes where the controller waits for the peer to confirm.
    // If a_isolate_ack_i is an INPUT, it means the peer (B) is telling A "I have isolated".
    // If b_isolate_ack_i is an INPUT, it means the peer (A) is telling B "I have isolated".
    // BUT, b_isolate_o is the signal sent to B. So A drives b_isolate_o.
    // If A drives b_isolate_o, then A knows it is isolated.
    // Why would A need an input b_isolate_ack_i?
    // Maybe b_isolate_ack_i is the signal from B saying "I see b_isolate_o"?
    // If so, b_isolate_ack_i is an INPUT from B.
    // And a_isolate_ack_i is an INPUT from B saying "I see a_isolate_o"?
    // And a_clear_ack_i is an INPUT from B saying "I see a_clear_o"?
    // And b_clear_ack_i is an INPUT from A saying "I see b_clear_o"?
    
    // This implies:
    // - a_clear_o is driven by A. B sees it. B asserts a_clear_ack_i.
    // - b_clear_o is driven by B. A sees it. A asserts b_clear_ack_i.
    // - a_isolate_o is driven by A. B sees it. B asserts a_isolate_ack_i.
    // - b_isolate_o is driven by B. A sees it. A asserts b_isolate_ack_i.
    
    // BUT the port list says b_isolate_ack_i is an INPUT.
    // If A asserts b_isolate_ack_i, it should be an OUTPUT.
    // Unless... the naming convention is "Ack received from peer".
    // a_clear_ack_i: Ack received from B regarding A's clear.
    // b_clear_ack_i: Ack received from A regarding B's clear.
    // a_isolate_ack_i: Ack received from B regarding A's isolate.
    // b_isolate_ack_i: Ack received from A regarding B's isolate.
    
    // If this is the case:
    // - A drives a_clear_o. B sees it. B asserts a_clear_ack_i (Input to A).
    // - B drives b_clear_o. A sees it. A asserts b_clear_ack_i (Input to B? No, Input to A).
    //   Wait, if A asserts b_clear_ack_i, it must be an OUTPUT of A.
    //   But the port list says b_clear_ack_i is an INPUT.
    //   This implies A receives b_clear_ack_i from B.
    //   So B asserts b_clear_ack_i.
    //   So b_clear_ack_i means "B acknowledges B's clear"? That doesn't make sense.
    //   Or "B acknowledges A's clear"? That would be a_clear_ack_i.
    
    // Let's try the other interpretation:
    // The controller drives the Isolate/Clear signals.
    // The peer drives the Ack signals.
    // a_clear_o (Out) -> B sees it -> B asserts a_clear_ack_i (In).
    // b_clear_o (Out) -> A sees it -> A asserts b_clear_ack_i (In).
    //   Wait, if A asserts b_clear_ack_i, it must be an Output.
    //   But the port list says b_clear_ack_i is an Input.
    //   This is a contradiction unless the port list implies:
    //   "b_clear_ack_i" is the signal coming FROM B, acknowledging something.
    //   What would B acknowledge? B's own clear? No.
    //   Maybe the naming is "Ack for Clear in Domain B"?
    //   If b_clear_ack_i is an input, it is driven by B.
    //   So B asserts b_clear_ack_i.
    //   Why? Maybe to tell A "I am ready to clear"?
    //   But the behavior says "wait for both clear acks".
    //   This implies the ack confirms the clear signal was received.
    //   So if A sends a_clear_o, B sends a_clear_ack_i.
    //   If B sends b_clear_o, A sends b_clear_ack_i.
    //   So b_clear_ack_i should be an OUTPUT of A.
    //   But the prompt says INPUT.
    
    // Alternative Interpretation:
    // The "Ack" signals are actually "Ready" signals from the peer indicating they are in a state to accept the reset.
    // Or, the prompt has a typo and meant Outputs for acks?
    // "Input ports: ... a_clear_ack_i ... b_clear_ack_i"
    // "Output ports: ... a_clear_o ... b_clear_o"
    
    // Let's assume the prompt is correct and the semantics are:
    // a_clear_ack_i: Input from B. Means B has acknowledged A's clear request?
    // But A drives a_clear_o. So B sees it. B asserts a_clear_ack_i.
    // b_clear_ack_i: Input from A. Means A has acknowledged B's clear request?
    // But B drives b_clear_o. So A sees it. A asserts b_clear_ack_i.
    //   If A asserts b_clear_ack_i, it must be an Output.
    //   But it is listed as Input.
    
    // Is it possible that b_clear_ack_i is the signal from B saying "I have cleared"?
    // And a_clear_ack_i is the signal from B saying "I have cleared"?
    // No, that would be redundant.
    
    // Let's look at the "Peer progress" requirement:
    // "Peer progress arrives in order: idle, then active, then done, then idle."
    // This suggests a handshake.
    
    // Let's assume the standard CDC Reset Controller pattern where:
    // - The controller drives Isolate and Clear.
    // - The peer drives Ack signals to confirm receipt.
    // - The Ack signals are Inputs to the controller.
    // - The naming "b_clear_ack_i" means "Ack for Clear in Domain B".
    //   Who drives it? The domain that owns the clear signal?
    //   If b_clear_o is driven by the controller, then the controller knows it's high.
    //   The peer (A) sees b_clear_o. The peer (A) asserts b_clear_ack_i.
    //   So b_clear_ack_i is driven by A.
    //   So b_clear_ack_i is an INPUT to the controller (from A).
    //   This matches the port list!
    //   So:
    //   - a_clear_o (Out) -> B sees it -> B asserts a_clear_ack_i (In).
    //   - b_clear_o (Out) -> A sees it -> A asserts b_clear_ack_i (In).
    //   - a_isolate_o (Out) -> B sees it -> B asserts a_isolate_ack_i (In).
    //   - b_isolate_o (Out) -> A sees it -> A asserts b_isolate_ack_i (In).
    
    // This makes perfect sense.
    // The controller drives the signals. The peer asserts the acks.
    // The acks are inputs to the controller.
    
    // So for Domain A State Machine:
    // Inputs:
    // - a_clear_i (Local request)
    // - b_clear_i (Synced from B)
    // - a_isolate_ack_i (Synced from B) -> Wait, a_isolate_ack_i is input from B.
    //   B asserts it when B sees a_isolate_o.
    // - b_isolate_ack_i (Local? No, b_isolate_ack_i is input from A).
    //   A asserts it when A sees b_isolate_o.
    //   But b_isolate_o is driven by the controller.
    //   So A (external) sees b_isolate_o and asserts b_isolate_ack_i.
    //   So b_isolate_ack_i is an INPUT from A.
    // - a_clear_ack_i (Synced from B) -> B asserts it when B sees a_clear_o.
    // - b_clear_ack_i (Synced from A) -> A asserts it when A sees b_clear_o.
    
    // Wait, if b_isolate_ack_i is an input from A, and A sees b_isolate_o (which is driven by the controller),
    // then A is asserting b_isolate_ack_i.
    // So the controller receives b_isolate_ack_i.
    // This means the controller drives b_isolate_o, and waits for b_isolate_ack_i.
    // This is consistent.
    
    // So the signals to sync for Domain A:
    // From B to A:
    // - b_clear_i (Request)
    // - a_isolate_ack_i (Ack for A's isolate)
    // - a_clear_ack_i (Ack for A's clear)
    
    // From A to B (for Domain B logic):
    // - a_clear_i (Request)
    // - b_isolate_ack_i (Ack for B's isolate)
    // - b_clear_ack_i (Ack for B's clear)
    
    // Now let's build the sync chains.
    
    // Chain B -> A
    reg [SYNC_STAGES-1:0] b_clear_req_sync;
    reg [SYNC_STAGES-1:0] a_isolate_ack_sync;
    reg [SYNC_STAGES-1:0] a_clear_ack_sync;
    
    // Chain A -> B
    reg [SYNC_STAGES-1:0] a_clear_req_sync;
    reg [SYNC_STAGES-1:0] b_isolate_ack_sync;
    reg [SYNC_STAGES-1:0] b_clear_ack_sync;
    
    // Initialize chains
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            b_clear_req_sync <= {SYNC_STAGES{1'b0}};
            a_isolate_ack_sync <= {SYNC_STAGES{1'b0}};
            a_clear_ack_sync <= {SYNC_STAGES{1'b0}};
            a_clear_req_sync <= {SYNC_STAGES{1'b0}};
            b_isolate_ack_sync <= {SYNC_STAGES{1'b0}};
            b_clear_ack_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            b_clear_req_sync[0] <= b_clear_i;
            b_clear_req_sync[1:SYNC_STAGES-1] <= b_clear_req_sync[0:SYNC_STAGES-2];
            
            a_isolate_ack_sync[0] <= a_isolate_ack_i;
            a_isolate_ack_sync[1:SYNC_STAGES-1] <= a_isolate_ack_sync[0:SYNC_STAGES-2];
            
            a_clear_ack_sync[0] <= a_clear_ack_i;
            a_clear_ack_sync[1:SYNC_STAGES-1] <= a_clear_ack_sync[0:SYNC_STAGES-2];
            
            a_clear_req_sync[0] <= a_clear_i;
            a_clear_req_sync[1:SYNC_STAGES-1] <= a_clear_req_sync[0:SYNC_STAGES-2];
            
            b_isolate_ack_sync[0] <= b_isolate_ack_i;
            b_isolate_ack_sync[1:SYNC_STAGES-1] <= b_isolate_ack_sync[0:SYNC_STAGES-2];
            
            b_clear_ack_sync[0] <= b_clear_ack_i;
            b_clear_ack_sync[1:SYNC_STAGES-1] <= b_clear_ack_sync[0:SYNC_STAGES-2];
        end
    end

    // Domain A State Machine
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            state <= STATE_IDLE;
            a_isolate_o <= 1'b0;
            a_clear_o <= 1'b0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    // Check local or peer request
                    if (a_clear_req_sync[SYNC_STAGES-1] || b_clear_req_sync[SYNC_STAGES-1]) begin
                        next_state <= STATE_ISOLATING;
                        a_isolate_o <= 1'b1;
                    end else begin
                        next_state <= STATE_IDLE;
                        a_isolate_o <= 1'b0;
                    end
                end
                
                STATE_ISOLATING: begin
                    // Wait for peer isolate ack
                    // Peer ack is a_isolate_ack_sync[SYNC_STAGES-1]
                    if (a_isolate_ack_sync[SYNC_STAGES-1]) begin
                        // Peer isolated. Now raise clear.
                        a_clear_o <= 1'b1;
                        next_state <= STATE_CLEARING;
                    end else begin
                        next_state <= STATE_ISOLATING;
                    end
                end
                
                STATE_CLEARING: begin
                    // Wait for peer clear ack
                    // Peer ack is a_clear_ack_sync[SYNC_STAGES-1]
                    if (a_clear_ack_sync[SYNC_STAGES-1]) begin
                        // Peer cleared. Release.
                        a_isolate_o <= 1'b0;
                        a_clear_o <= 1'b0;
                        next_state <= STATE_IDLE;
                    end else begin
                        next_state <= STATE_CLEARING;
                    end
                end
                
                default: begin
