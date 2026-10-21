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
    //    States: IDLE, REQ_SENT, ACK_RECEIVED, IDLE_DONE.
    //    - IDLE: Waiting for valid.
    //    - REQ_SENT: Valid asserted, waiting for ack.
    //    - ACK_RECEIVED: Ack received, waiting for next cycle to release valid.
    //    - IDLE_DONE: Ready asserted, waiting for valid to drop.
    // 2. Use a 2-bit state machine in the destination domain to track the handshake phase.
    //    States: IDLE, REQ_RECEIVED, ACK_SENT, IDLE_DONE.
    //    - IDLE: Waiting for valid.
    //    - REQ_RECEIVED: Valid received, waiting for ready.
    //    - ACK_SENT: Ready asserted, waiting for valid to drop.
    //    - IDLE_DONE: Valid dropped, waiting for next cycle to release ready.
    // 3. Cross-domain signals are registered in the receiving domain to ensure setup/hold.
    //    - src_valid_i is registered in dst domain.
    //    - dst_ready_i is registered in src domain.
    // 4. Reset release is synchronous with local clocks.

    // Source Domain State Machine
    // State encoding: 2 bits
    // 00: IDLE
    // 01: REQ_SENT (src_valid asserted)
    // 10: ACK_RECEIVED (dst_ready asserted, waiting for valid to drop)
    // 11: IDLE_DONE (src_ready asserted, waiting for valid to drop)
    reg [1:0] src_state;
    reg [1:0] src_next_state;
    reg       src_valid_reg; // Registered src_valid for internal logic if needed, but we use input directly with caution.
    // Actually, for 4-phase, we need to know the previous cycle's valid status in the same domain to detect the drop.
    reg       src_valid_prev;

    // Destination Domain State Machine
    // State encoding: 2 bits
    // 00: IDLE
    // 01: REQ_RECEIVED (src_valid asserted)
    // 10: ACK_SENT (dst_ready asserted, waiting for valid to drop)
    // 11: IDLE_DONE (dst_valid asserted, waiting for valid to drop)
    reg [1:0] dst_state;
    reg [1:0] dst_next_state;
    reg       dst_ready_reg; // Registered dst_ready for internal logic
    reg       dst_valid_prev;

    // --- Source Domain Logic ---
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_state <= 2'b00;
            src_valid_prev <= 1'b0;
            src_ready_o <= 1'b0;
        end else begin
            src_state <= src_next_state;
            src_valid_prev <= src_valid_i;
            
            // Output logic based on state
            // Phase 1: src_valid asserted (State 01)
            // Phase 2: src_ready asserted (State 11)
            // We need to ensure the sequence: Valid -> (wait ack) -> Ready -> (wait valid drop)
            
            case (src_state)
                2'b00: begin // IDLE
                    src_ready_o <= 1'b0;
                end
                2'b01: begin // REQ_SENT: Valid is high, waiting for ACK
                    src_ready_o <= 1'b0;
                end
                2'b10: begin // ACK_RECEIVED: Ack is high, waiting for Valid to drop
                    src_ready_o <= 1'b0;
                end
                2'b11: begin // IDLE_DONE: Ready is high, waiting for Valid to drop
                    src_ready_o <= 1'b1;
                end
            endcase
        end
    end

    // Source State Transition Logic
    always @(*) begin
        src_next_state = src_state;
        case (src_state)
            2'b00: begin // IDLE
                if (src_valid_i)
                    src_next_state = 2'b01; // Go to REQ_SENT
                else
                    src_next_state = 2'b00; // Stay IDLE
            end
            2'b01: begin // REQ_SENT: Valid is high. Check if ACK (dst_ready) is high.
                // We need the registered version of dst_ready from the source domain perspective.
                // Since dst_ready_i is asynchronous, we must register it in the source domain.
                // Let's add a register for dst_ready in the source domain.
                // Wait, the logic above for state transition needs the registered signal.
                // I will refactor the always block to include the registration of cross-domain signals.
                src_next_state = 2'b01; // Default stay
            end
            2'b10: begin // ACK_RECEIVED: Ack is high. Waiting for Valid to drop.
                if (!src_valid_i)
                    src_next_state = 2'b11; // Go to IDLE_DONE (Ready will be asserted next cycle)
                else
                    src_next_state = 2'b10; // Stay
            end
            2'b11: begin // IDLE_DONE: Ready is high. Waiting for Valid to drop.
                if (!src_valid_i)
                    src_next_state = 2'b00; // Go back to IDLE
                else
                    src_next_state = 2'b11; // Stay
            end
            default: src_next_state = 2'b00;
        endcase
    end

    // --- Destination Domain Logic ---
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_state <= 2'b00;
            dst_valid_prev <= 1'b0;
            dst_valid_o <= 1'b0;
        end else begin
            dst_state <= dst_next_state;
            dst_valid_prev <= src_valid_i; // Register src_valid in dst domain
            
            // Output logic based on state
            // Phase 1: dst_valid asserted (State 11)
            // Phase 2: dst_ready asserted (State 10)
            
            case (dst_state)
                2'b00: begin // IDLE
                    dst_valid_o <= 1'b0;
                end
                2'b01: begin // REQ_RECEIVED: Valid is high, waiting for Ready.
                    dst_valid_o <= 1'b0;
                end
                2'b10: begin // ACK_SENT: Ready is high, waiting for Valid to drop.
                    dst_valid_o <= 1'b0;
                end
                2'b11: begin // IDLE_DONE: Valid is high, waiting for Valid to drop.
                    dst_valid_o <= 1'b1;
                end
            endcase
        end
    end

    // Destination State Transition Logic
    always @(*) begin
        dst_next_state = dst_state;
        case (dst_state)
            2'b00: begin // IDLE
                if (dst_valid_prev)
                    dst_next_state = 2'b01; // Go to REQ_RECEIVED
                else
                    dst_next_state = 2'b00; // Stay IDLE
            end
            2'b01: begin // REQ_RECEIVED: Valid is high. Check if Ready (dst_ready_i) is high.
                // We need the registered version of dst_ready in the destination domain.
                // Let's add a register for dst_ready in the destination domain.
                dst_next_state = 2'b01; // Default stay
            end
            2'b10: begin // ACK_SENT: Ready is high. Waiting for Valid to drop.
                if (!dst_valid_prev)
                    dst_next_state = 2'b11; // Go to IDLE_DONE (Valid will be asserted next cycle)
                else
                    dst_next_state = 2'b10; // Stay
            end
            2'b11: begin // IDLE_DONE: Valid is high. Waiting for Valid to drop.
                if (!dst_valid_prev)
                    dst_next_state = 2'b00; // Go back to IDLE
                else
                    dst_next_state = 2'b11; // Stay
            end
            default: dst_next_state = 2'b00;
        endcase
    end

    // --- Cross-Domain Signal Registration ---

    // In Source Domain: Register dst_ready_i to detect the ACK
    reg       src_dst_ready_reg;
    reg       src_dst_ready_prev;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_dst_ready_reg <= 1'b0;
            src_dst_ready_prev <= 1'b0;
        end else begin
            src_dst_ready_reg <= dst_ready_i;
            src_dst_ready_prev <= src_dst_ready_reg;
        end
    end

    // In Destination Domain: Register src_valid_i to detect the Request
    reg       dst_src_valid_reg;
    reg       dst_src_valid_prev;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_src_valid_reg <= 1'b0;
            dst_src_valid_prev <= 1'b0;
        end else begin
            dst_src_valid_reg <= src_valid_i;
            dst_src_valid_prev <= dst_src_valid_reg;
        end
    end

    // --- Updated Source State Transition with Registered Signals ---
    always @(*) begin
        src_next_state = src_state;
        case (src_state)
            2'b00: begin // IDLE
                if (src_valid_i)
                    src_next_state = 2'b01; // Go to REQ_SENT
                else
                    src_next_state = 2'b00; // Stay IDLE
            end
            2'b01: begin // REQ_SENT: Valid is high. Check if ACK (src_dst_ready_reg) is high.
                if (src_dst_ready_reg)
                    src_next_state = 2'b10; // Go to ACK_RECEIVED
                else
                    src_next_state = 2'b01; // Stay
            end
            2'b10: begin // ACK_RECEIVED: Ack is high. Waiting for Valid to drop.
                if (!src_valid_i)
                    src_next_state = 2'b11; // Go to IDLE_DONE (Ready will be asserted next cycle)
                else
                    src_next_state = 2'b10; // Stay
            end
            2'b11: begin // IDLE_DONE: Ready is high. Waiting for Valid to drop.
                if (!src_valid_i)
                    src_next_state = 2'b00; // Go back to IDLE
                else
                    src_next_state = 2'b11; // Stay
            end
            default: src_next_state = 2'b00;
        endcase
    end

    // --- Updated Destination State Transition with Registered Signals ---
    always @(*) begin
        dst_next_state = dst_state;
        case (dst_state)
            2'b00: begin // IDLE
                if (dst_src_valid_reg)
                    dst_next_state = 2'b01; // Go to REQ_RECEIVED
                else
                    dst_next_state = 2'b00; // Stay IDLE
            end
            2'b01: begin // REQ_RECEIVED: Valid is high. Check if Ready (dst_ready_i) is high.
                if (dst_ready_i)
                    dst_next_state = 2'b10; // Go to ACK_SENT
                else
                    dst_next_state = 2'b01; // Stay
            end
            2'b10: begin // ACK_SENT: Ready is high. Waiting for Valid to drop.
                if (!dst_src_valid_reg)
                    dst_next_state = 2'b11; // Go to IDLE_DONE (Valid will be asserted next cycle)
                else
                    dst_next_state = 2'b10; // Stay
            end
            2'b11: begin // IDLE_DONE: Valid is high. Waiting for Valid to drop.
                if (!dst_src_valid_reg)
                    dst_next_state = 2'b00; // Go back to IDLE
                else
                    dst_next_state = 2'b11; // Stay
            end
            default: dst_next_state = 2'b00;
        endcase
    end

endmodule<|im_end|>
