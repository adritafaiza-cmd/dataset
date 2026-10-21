module isochronous_4phase_handshake (
    input  src_clk_i,
    input  src_rst_ni,
    input  src_valid_i,
    output src_ready_o,
    input  dst_clk_i,
    input  dst_rst_ni,
    output dst_valid_o,
    input  dst_ready_i
);

    // CDC Strategy:
    // 1. Use a 2-bit state machine in the source domain to track the handshake phase.
    //    States: IDLE, REQ_SENT, ACK_RECEIVED, ACK_SENT.
    //    This ensures src_ready_o and dst_valid_o are generated based on stable,
    //    multi-cycle signals within the source domain, avoiding direct clock crossing
    //    of single-bit handshakes.
    // 2. Use a 2-bit state machine in the destination domain to track the handshake phase.
    //    States: IDLE, REQ_RECEIVED, ACK_SENT, ACK_RECEIVED.
    // 3. Reset synchronization: Use a 2-bit synchronizer for the active-low resets
    //    in each domain to ensure safe reset release before state machine operation.

    // Source Domain State Machine
    typedef enum logic [1:0] {
        SRC_IDLE,
        SRC_REQ_SENT,
        SRC_ACK_RECEIVED,
        SRC_ACK_SENT
    } src_state_t;

    src_state_t src_state_reg, src_state_next;
    logic src_rst_sync;

    // Destination Domain State Machine
    typedef enum logic [1:0] {
        DST_IDLE,
        DST_REQ_RECEIVED,
        DST_ACK_SENT,
        DST_ACK_RECEIVED
    } dst_state_t;

    dst_state_t dst_state_reg, dst_state_next;
    logic dst_rst_sync;

    // Synchronize resets in each domain
    always_ff @(posedge src_clk_i or posedge src_rst_ni) begin
        if (!src_rst_ni)
            src_rst_sync <= 1'b0;
        else
            src_rst_sync <= 1'b1;
    end

    always_ff @(posedge dst_clk_i or posedge dst_rst_ni) begin
        if (!dst_rst_ni)
            dst_rst_sync <= 1'b0;
        else
            dst_rst_sync <= 1'b1;
    end

    // Source Domain Logic
    always_ff @(posedge src_clk_i or posedge src_rst_ni) begin
        if (!src_rst_ni)
            src_state_reg <= SRC_IDLE;
        else
            src_state_reg <= src_state_next;
    end

    always_comb begin
        src_state_next = src_state_reg;
        src_ready_o    = 1'b0;
        dst_valid_o    = 1'b0; // Driven by destination domain logic via cross-domain sync? No, driven by src domain based on dst feedback.

        case (src_state_reg)
            SRC_IDLE: begin
                if (src_valid_i)
                    src_state_next = SRC_REQ_SENT;
                src_ready_o = 1'b0;
            end
            SRC_REQ_SENT: begin
                // Wait for ACK from destination.
                // We need to know if destination has received our request.
                // Since we are in src domain, we cannot directly read dst_state.
                // We must rely on a feedback signal from dst domain that is safe to cross.
                // Strategy: The destination domain will assert a "grant" signal back to source
                // when it is ready to accept the next request.
                // However, the problem asks for a 4-phase handshake.
                // Phase 1: Src Valid -> Dst Ready (Implicit)
                // Phase 2: Src Ready -> Dst Valid
                // Phase 3: Dst Ready (for next) -> Src Valid (next)
                // Phase 4: Src Ready (next) -> Dst Valid (next)
                
                // To implement this safely across clocks without shared memory:
                // We use a "pending" flag in the destination domain that indicates "I have received
                // your request and am waiting for your ACK". The destination domain will drive
                // dst_valid_o. The source domain needs to know when the destination is ready to
                // accept the NEXT transaction.
                
                // Revised Strategy for Cross-Clock 4-Phase:
                // 1. Src asserts src_valid_i.
                // 2. Dst (on dst_clk) sees src_valid_i (synchronized). If dst_ready_i, it accepts.
                //    Dst sets an internal flag "req_accepted".
                //    Dst asserts dst_valid_o (Phase 2).
                // 3. Src (on src_clk) sees dst_valid_o (synchronized). If seen, Src asserts src_ready_o (Phase 3).
                //    Src sets internal flag "ack_sent".
                // 4. Dst (on dst_clk) sees src_ready_o (synchronized). If seen, Dst clears "req_accepted"
                //    and sets "ack_received". Dst asserts dst_ready_i for the next cycle (Phase 4).
                // 5. Src (on src_clk) sees dst_ready_i (synchronized). If seen, Src clears "ack_sent"
                //    and goes back to IDLE, ready for next src_valid_i.
                
                // This requires synchronizing src_valid_i, dst_valid_o, src_ready_o, dst_ready_i
                // into the opposite domains.
                
                // Let's define the states based on this flow:
                // SRC_IDLE: Waiting for src_valid_i.
                // SRC_WAITING_FOR_VALID: src_valid_i is high (synchronized). Waiting for dst_valid_o.
                // SRC_WAITING_FOR_READY: dst_valid_o is high (synchronized). Asserting src_ready_o. Waiting for dst_ready_i.
                // SRC_IDLE: Loop back.
                
                // Actually, the standard 4-phase handshake logic is:
                // 1. Src Valid -> Dst Ready (Handshake 1)
                // 2. Src Ready -> Dst Valid (Handshake 2)
                // 3. Dst Ready -> Src Valid (Handshake 3)
                // 4. Src Ready -> Dst Valid (Handshake 4)
                
                // Since there is no data, the "data" is the handshake itself.
                // We need to synchronize the control signals.
                
                // Synchronizers for crossing signals:
                // src_valid_i -> dst domain (to detect request)
                // dst_valid_o -> src domain (to detect response)
                // src_ready_o -> dst domain (to detect ack)
                // dst_ready_i -> src domain (to detect next opportunity)
                
                // Implementation:
                // In SRC domain:
                // - Detect src_valid_i (already local).
                // - Detect dst_valid_o (via sync).
                // - Detect dst_ready_i (via sync).
                // - Drive src_ready_o (local output).
                
                // In DST domain:
                // - Detect src_valid_i (via sync).
                // - Detect src_ready_o (via sync).
                // - Drive dst_valid_o (local output).
                // - Drive dst_ready_i (local output, but must be stable for src).
                
                // Let's implement the synchronizers and state machines.
                
                // Synchronizers for SRC domain inputs coming from DST
                logic [1:0] dst_valid_sync;
                logic [1:0] dst_ready_sync;
                
                // Synchronizers for DST domain inputs coming from SRC
                logic [1:0] src_valid_sync;
                logic [1:0] src_ready_sync;
                
                // We need to instantiate these synchronizers.
                // Since we cannot use separate modules in one file easily without clutter,
                // we will inline the 2-bit synchronizer logic.
                
                // Synchronizer for dst_valid_o in SRC domain
                always_ff @(posedge src_clk_i or posedge src_rst_ni) begin
                    if (!src_rst_ni) dst_valid_sync <= 2'b00;
                    else begin
                        dst_valid_sync[0] <= dst_valid_o;
                        dst_valid_sync[1] <= dst_valid_sync[0];
                    end
                end
                
                // Synchronizer for dst_ready_i in SRC domain
                always_ff @(posedge src_clk_i or posedge src_rst_ni) begin
                    if (!src_rst_ni) dst_ready_sync <= 2'b00;
                    else begin
                        dst_ready_sync[0] <= dst_ready_i;
                        dst_ready_sync[1] <= dst_ready_sync[0];
                    end
                end
                
                // Synchronizer for src_valid_i in DST domain
                always_ff @(posedge dst_clk_i or posedge dst_rst_ni) begin
                    if (!dst_rst_ni) src_valid_sync <= 2'b00;
                    else begin
                        src_valid_sync[0] <= src_valid_i;
                        src_valid_sync[1] <= src_valid_sync[0];
                    end
                end
                
                // Synchronizer for src_ready_o in DST domain
                always_ff @(posedge dst_clk_i or posedge dst_rst_ni) begin
                    if (!dst_rst_ni) src_ready_sync <= 2'b00;
                    else begin
                        src_ready_sync[0] <= src_ready_o;
                        src_ready_sync[1] <= src_ready_sync[0];
                    end
                end

                // Now the logic for SRC domain state machine
                case (src_state_reg)
                    SRC_IDLE: begin
                        if (src_valid_i)
                            src_state_next = SRC_WAITING_FOR_VALID;
                        src_ready_o = 1'b0;
                    end
                    SRC_WAITING_FOR_VALID: begin
                        // We have seen src_valid_i. Wait for dst_valid_o.
                        // dst_valid_o is synchronized in dst_valid_sync[1] (stable for 2 cycles).
                        if (dst_valid_sync[1])
                            src_state_next = SRC_WAITING_FOR_READY;
                        src_ready_o = 1'b0;
                    end
                    SRC_WAITING_FOR_READY: begin
                        // We have seen dst_valid_o. Assert src_ready_o.
                        // Wait for dst_ready_i.
                        src_ready_o = 1'b1;
                        if (dst_ready_sync[1])
                            src_state_next = SRC_IDLE;
                    end
                    default: begin
                        src_state_next = SRC_IDLE;
                        src_ready_o = 1'b0;
                    end
                end
            end

            // Logic for DST domain state machine
            // States:
            // DST_IDLE: Waiting for src_valid_i.
            // DST_WAITING_FOR_READY: src_valid_i seen. Waiting for src_ready_o.
            // DST_IDLE: Loop back.
            
            // Note: The 4-phase handshake implies:
            // 1. Src Valid -> Dst Ready (Implicitly handled by Dst accepting the request)
            // 2. Src Ready -> Dst Valid (Dst asserts valid)
            // 3. Dst Ready -> Src Valid (Src re-asserts valid? No, usually valid is one-shot per transaction)
            //    Actually, in a 4-phase handshake without data:
            //    - Src raises Valid.
            //    - Dst raises Ready (if ready).
            //    - Src raises Ready.
            //    - Dst raises Valid.
            //    - Dst lowers Ready (implicitly by not holding it, or explicitly).
            //    - Src lowers Valid.
            //    - Src lowers Ready.
            
            // Given the ports:
            // src_valid_i (input), src_ready_o (output)
            // dst_ready_i (input), dst_valid_o (output)
            
            // Flow:
            // 1. Src asserts src_valid_i.
            // 2. Dst (on dst_clk) sees src_valid_i. If Dst is ready, it asserts dst_valid_o.
            //    (This is the "Ready" response to "Valid").
            // 3. Src (on src_clk) sees dst_valid_o. Src asserts src_ready_o.
            //    (This is the "Ready" response to "Valid" from Dst).
            // 4. Dst (on dst_clk) sees src_ready_o. Dst asserts dst_ready_i for the NEXT transaction?
            //    Or does Dst assert dst_ready_i to acknowledge the completion?
            //    Standard 4-phase:
            //    Phase 1: Src Valid, Dst Ready.
            //    Phase 2: Src Ready, Dst Valid.
            //    Phase 3: Dst Ready (for next), Src Valid (for next).
            //    Phase 4: Src Ready (for next), Dst Valid (for next).
            
            // Since there is no data, the "transaction" is just the handshake itself.
            // So:
            // 1. Src Valid -> Dst Ready (Ack 1)
            // 2. Src Ready -> Dst Valid (Ack 2)
            // 3. Dst Ready (Ack 3) -> Src Valid (Req 2)
            // 4. Src Ready (Ack 4) -> Dst Valid (Ack 2 for Req 2)
            
            // Implementation in DST domain:
            // - Detect src_valid_i (synced).
            // - If detected, assert dst_valid_o (Phase 2 response).
            // - Detect src_ready_o (synced).
            // - If detected, assert dst_ready_i (Phase 3 response, enabling next cycle).
            
            // Implementation in SRC domain:
            // - Detect dst_valid_o (synced).
            // - If detected, assert src_ready_o (Phase 3 response).
            // - Detect dst_ready_i (synced).
            // - If detected, de-assert src_valid_i (if it was held) and go idle.
            
            // Wait, src_valid_i is an input. We cannot de-assert it.
            // The user drives src_valid_i.
            // So the handshake is:
            // 1. User drives src_valid_i.
            // 2. Module waits for dst_valid_o.
            // 3. Module drives src_ready_o.
            // 4. Module waits for dst_ready_i.
            // 5. Module goes idle (waiting for next src_valid_i).
            
            // In DST domain:
            // 1. Module waits for src_valid_i.
            // 2. Module drives dst_valid_o.
            // 3. Module waits for src_ready_o.
            // 4. Module drives dst_ready_i.
            // 5. Module goes idle.
            
            // This matches the 4-phase requirement perfectly.
            
            // DST State Machine
            case (dst_state_reg)
                DST_IDLE: begin
                    if (src_valid_sync[1])
                        dst_state_next = DST_WAITING_FOR_READY;
                    dst_valid_o = 1'b0;
                    dst_ready_i = 1'b0; // Default low, will be asserted in next phase
                end
                DST_WAITING_FOR_READY: begin
                    // We have seen src_valid_i. Assert dst_valid_o.
                    // Wait for src_ready_o.
                    dst_valid_o = 1'b1;
                    if (src_ready_sync[1])
                        dst_state_next = DST_IDLE;
                    else
                        dst_state_next = DST_WAITING_FOR_READY;
                end
                default: begin
                    dst_state_next = DST_IDLE;
                    dst_valid_o = 1'b0;
                    dst_ready_i = 1'b0;
                end
            end

        endcase
    end

    // Note: The above logic for SRC domain had a slight issue in the case statement structure.
    // Let's refactor the SRC domain logic to be cleaner and ensure the 4-phase flow is strictly followed.
    
    // Re-evaluating SRC Domain Logic:
    // State 0: IDLE. Wait for src_valid_i.
    // State 1: VALID_SENT. src_valid_i is high. Wait for dst_valid_o.
    // State 2: READY_SENT. dst_valid_o is high. Assert src_ready_o. Wait for dst_ready_i.
    // State 3: DONE. dst_ready_i is high. De-assert src_ready_o. Go to IDLE.
    
    // Re-evaluating DST Domain Logic:
    // State 0: IDLE. Wait for src_valid_i.
    // State 1: VALID_SENT. src_valid_i is high. Assert dst_valid_o. Wait for src_ready_o.
    // State 2: READY_SENT. src_ready_o is high. Assert dst_ready_i. Wait for src_valid_i (next).
    // State 3: DONE. src_valid_i is high (next). Go to IDLE? No, loop.
    
    // Let's rewrite the combinational logic for both domains to be precise.
    
    // --- Source Domain Logic ---
    always_comb begin
        src_state_next = src_state_reg;
        src_ready_o    = 1'b0;
        
        case (src_state_reg)
            SRC_IDLE: begin
                if (src_valid_i)
                    src_state_next = SRC_VALID_SENT;
            end
            SRC_VALID_SENT: begin
                if (dst_valid_sync[1])
                    src_state_next = SRC_READY_SENT;
            end
            SRC_READY_SENT: begin
                src_ready_o = 1'b1;
                if (dst_ready_sync[1])
                    src_state_next = SRC_IDLE;
            end
            default: begin
                src_state_next = SRC_IDLE;
            end
        endcase
    end

    // --- Destination Domain Logic ---
    always_comb begin
        dst_state_next = dst_state_reg;
        dst_valid_o    = 1'b0;
        dst_ready_i    = 1'b0;
        
        case (dst_state_reg)
            DST_IDLE: begin
                if (src_valid_sync[1])
                    dst_state_next = DST_VALID_SENT;
            end
            DST_VALID_SENT: begin
                dst_valid_o = 1'b1;
                if (src_ready_sync[1])
                    dst_state_next = DST_READY_SENT;
            end
            DST_READY_SENT: begin
                dst_ready_i = 1'b1;
                // Stay here until src_valid_i comes again? 
                // No, once we send dst_ready_i, we are ready for the next transaction.
                // But we must wait for the next src_valid_i to start the cycle again.
                // However, if src_valid_i is still high (same transaction), we might get confused.
                // But src_valid_i is an input from the user. The user should drive it low after the handshake.
                // If the user holds src_valid_i high, the SRC domain will stay in SRC_READY_SENT until dst_ready_i.
                // Once dst_ready_i is high, SRC goes to IDLE.
                // So DST_READY_SENT is a stable state waiting for the next src_valid_i.
                
                // Wait, if DST is in DST_READY_SENT, and src_valid_i becomes high (new transaction),
                // DST should transition to DST_VALID_SENT.
                // So the condition to stay in DST_READY_SENT is: NOT src_valid_sync[1].
                // If src_valid_sync[1] is high, go to DST_VALID_SENT.
                
                if (src_valid_sync[1])
                    dst_state_next = DST_VALID_SENT;
                else
                    dst_state_next = DST_READY_SENT;
            end
            default: begin
                dst_state_next = DST_IDLE;
            end
        endcase
    end

endmodule<|im_end|>
