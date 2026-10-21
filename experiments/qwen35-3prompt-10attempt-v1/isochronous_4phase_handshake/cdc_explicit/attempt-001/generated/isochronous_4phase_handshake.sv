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
    //    States: IDLE (00), REQ (01), ACK (10), IDLE_DONE (11).
    //    This ensures the transition from REQ to ACK is synchronized to dst_clk_i.
    // 2. Use a 2-bit state machine in the destination domain to track the response phase.
    //    States: IDLE (00), REQ (01), ACK (10), IDLE_DONE (11).
    //    This ensures the transition from ACK to IDLE_DONE is synchronized to src_clk_i.
    // 3. Reset release is handled synchronously within each domain.
    // 4. No multi-bit data is transferred; only control signals are exchanged via state transitions.

    // Source Domain State Machine
    // State Encoding:
    // 2'b00 = IDLE
    // 2'b01 = REQ (Waiting for ACK from dest)
    // 2'b10 = ACK (Waiting for dest to release ACK, then go to IDLE_DONE)
    // 2'b11 = IDLE_DONE (Ready to accept new request)
    reg [1:0] src_state, src_state_next;

    // Destination Domain State Machine
    // State Encoding:
    // 2'b00 = IDLE
    // 2'b01 = REQ (Waiting for ACK from src)
    // 2'b10 = ACK (Waiting for src to release ACK, then go to IDLE_DONE)
    // 2'b11 = IDLE_DONE (Ready to accept new request)
    reg [1:0] dst_state, dst_state_next;

    // Synchronous Reset Logic for Source Domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            src_state <= 2'b00;
        else
            src_state <= src_state_next;
    end

    // Synchronous Reset Logic for Destination Domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            dst_state <= 2'b00;
        else
            dst_state <= dst_state_next;
    end

    // Source Domain Next State Logic
    // Transitions:
    // IDLE -> REQ: When src_valid_i is high
    // REQ -> ACK: When dst_ready_i is sampled high (via cross-clock sync)
    // ACK -> IDLE_DONE: Always (after receiving ACK)
    // IDLE_DONE -> IDLE: Always (loop back)
    always @(*) begin
        src_state_next = src_state;
        case (src_state)
            2'b00: begin // IDLE
                if (src_valid_i)
                    src_state_next = 2'b01; // REQ
                else
                    src_state_next = 2'b00;
            end
            2'b01: begin // REQ
                // We need to know if dst_ready_i was high during the time we were in REQ.
                // Since we are in src domain, we cannot directly see dst_ready_i's effect on our state transition
                // without a cross-clock mechanism. However, the standard 4-phase handshake relies on the
                // destination domain acknowledging the request.
                // To implement this safely in Verilog without external FIFOs, we rely on the fact that
                // the destination domain will drive its state machine.
                // BUT, a pure state machine in src cannot "see" dst_ready_i to transition from REQ to ACK
                // unless we use a cross-clock register to capture dst_ready_i.
                //
                // Revised Strategy for Pure State Machine:
                // The "ACK" state in src is actually the state where we have received the ACK.
                // The transition from REQ to ACK happens when we detect that dst_ready_i has been asserted
                // in the previous cycle of dst_clk_i.
                //
                // To do this safely, we need a cross-clock register in the SRC domain to capture dst_ready_i.
                // Let's add a cross-clock register for dst_ready_i in the SRC domain.
                // Similarly, we need a cross-clock register for src_valid_i in the DST domain.
                
                // Wait, the problem asks for a complete module. Adding cross-clock registers inside
                // the same module is valid as long as they are synchronized.
                // We will use a 2-bit register to capture the handshake status from the other domain.
                
                // Actually, the cleanest way for a 4-phase handshake without data payload is:
                // 1. Src asserts valid.
                // 2. Dst samples valid and asserts ready.
                // 3. Src samples ready and deasserts valid (or moves to next phase).
                // 4. Dst samples deasserted valid and deasserts ready.
                //
                // This requires capturing the signal from the other domain.
                // Let's define cross-clock registers.
                
                // We need to capture dst_ready_i in the src domain to know when to move from REQ to ACK.
                // We need to capture src_valid_i in the dst domain to know when to move from REQ to ACK.
                
                // However, the state machine logic below assumes we have access to the cross-domain signals.
                // Let's define the cross-domain registers first.
                
                // Placeholder for logic that depends on cross-domain signals.
                // We will implement the cross-domain synchronization below.
                
                // For now, let's assume the cross-domain signals are available as inputs to this block.
                // But they are not ports. We must instantiate registers inside.
                
                // Let's restructure:
                // Src Domain:
                //   - State Machine
                //   - Register to capture dst_ready_i (synced to src_clk_i)
                // Dst Domain:
                //   - State Machine
                //   - Register to capture src_valid_i (synced to dst_clk_i)
                
                // Since we can't have separate always blocks for cross-domain registers easily without
                // duplicating logic, we will put the cross-domain registers in the respective domains.
                
                // Src Domain Logic:
                //   - Capture dst_ready_i into a register `dst_ready_synced` on src_clk_i.
                //   - Use `dst_ready_synced` to transition from REQ to ACK.
                
                // Dst Domain Logic:
                //   - Capture src_valid_i into a register `src_valid_synced` on dst_clk_i.
                //   - Use `src_valid_synced` to transition from REQ to ACK.
                
                // This is the standard approach.
                
                // Let's write the logic assuming `dst_ready_synced` and `src_valid_synced` are available.
                // We will define them in the respective domains.
                
                // Src Domain Next State Logic (using cross-domain signal)
                if (src_valid_i)
                    src_state_next = 2'b01; // REQ
                else if (src_state == 2'b01 && dst_ready_synced)
                    src_state_next = 2'b10; // ACK
                else if (src_state == 2'b10)
                    src_state_next = 2'b11; // IDLE_DONE
                else
                    src_state_next = 2'b00; // IDLE
            end
            2'b10: begin // ACK
                src_state_next = 2'b11; // IDLE_DONE
            end
            2'b11: begin // IDLE_DONE
                src_state_next = 2'b00; // IDLE
            end
            default: src_state_next = 2'b00;
        endcase
    end

    // Destination Domain Next State Logic (using cross-domain signal)
    always @(*) begin
        dst_state_next = dst_state;
        case (dst_state)
            2'b00: begin // IDLE
                if (src_valid_synced)
                    dst_state_next = 2'b01; // REQ
                else
                    dst_state_next = 2'b00;
            end
            2'b01: begin // REQ
                if (src_valid_synced == 1'b0)
                    dst_state_next = 2'b10; // ACK
                else
                    dst_state_next = 2'b01;
            end
            2'b10: begin // ACK
                dst_state_next = 2'b11; // IDLE_DONE
            end
            2'b11: begin // IDLE_DONE
                dst_state_next = 2'b00; // IDLE
            end
            default: dst_state_next = 2'b00;
        endcase
    end

    // Cross-Domain Synchronization Registers
    // In Source Domain: Capture dst_ready_i
    reg dst_ready_synced;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            dst_ready_synced <= 1'b0;
        else
            dst_ready_synced <= dst_ready_i;
    end

    // In Destination Domain: Capture src_valid_i
    reg src_valid_synced;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            src_valid_synced <= 1'b0;
        else
            src_valid_synced <= src_valid_i;
    end

    // Output Logic
    // src_ready_o is high when src_state is IDLE_DONE (2'b11)
    assign src_ready_o = (src_state == 2'b11);

    // dst_valid_o is high when dst_state is IDLE_DONE (2'b11)
    assign dst_valid_o = (dst_state == 2'b11);

endmodule<|im_end|>
