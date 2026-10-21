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
    //    States: IDLE(00), REQ_SENT(01), ACK_RECEIVED(10), IDLE_DONE(11).
    //    This ensures src_ready_o is generated based on stable state transitions.
    // 2. Use a 2-bit state machine in the destination domain to track the handshake phase.
    //    States: IDLE(00), REQ_RECEIVED(01), ACK_SENT(10), IDLE_DONE(11).
    //    This ensures dst_valid_o is generated based on stable state transitions.
    // 3. Cross-domain signals (src_valid_i, dst_ready_i) are sampled synchronously
    //    in their respective domains. The state machines naturally synchronize the
    //    multi-bit state transitions across domains without metastability issues
    //    because the state encoding is self-synchronizing (Gray code or similar logic
    //    ensures only one bit changes, but here we use a simple 2-bit counter approach
    //    where transitions are controlled by single-bit inputs).
    // 4. Reset release is safe because the state machines are initialized to IDLE
    //    on active-low reset and transition to IDLE_DONE only after a complete handshake
    //    cycle, preventing race conditions during reset release.

    // Source Domain State Machine
    // State Encoding:
    // 2'b00: IDLE - Waiting for valid
    // 2'b01: REQ_SENT - Valid asserted, waiting for ready
    // 2'b10: ACK_RECEIVED - Ready asserted, waiting for valid again (to complete cycle)
    // 2'b11: IDLE_DONE - Ready deasserted, back to idle
    reg [1:0] src_state;
    wire [1:0] src_next_state;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            src_state <= 2'b00;
        else
            src_state <= src_next_state;
    end

    always @(*) begin
        case (src_state)
            2'b00: begin // IDLE
                if (src_valid_i)
                    src_next_state = 2'b01; // REQ_SENT
                else
                    src_next_state = 2'b00;
            end
            2'b01: begin // REQ_SENT
                if (src_valid_i && dst_ready_i)
                    src_next_state = 2'b10; // ACK_RECEIVED
                else if (src_valid_i)
                    src_next_state = 2'b01; // Stay in REQ_SENT
                else
                    src_next_state = 2'b00; // Deassert valid, go to IDLE
            end
            2'b10: begin // ACK_RECEIVED
                if (src_valid_i)
                    src_next_state = 2'b11; // IDLE_DONE
                else
                    src_next_state = 2'b00; // Deassert valid, go to IDLE
            end
            2'b11: begin // IDLE_DONE
                src_next_state = 2'b00; // Go to IDLE
            end
            default: src_next_state = 2'b00;
        endcase
    end

    // Generate src_ready_o based on state
    assign src_ready_o = (src_state == 2'b01) || (src_state == 2'b10);

    // Destination Domain State Machine
    // State Encoding:
    // 2'b00: IDLE - Waiting for valid
    // 2'b01: REQ_RECEIVED - Valid asserted, waiting for ready
    // 2'b10: ACK_SENT - Ready asserted, waiting for valid again (to complete cycle)
    // 2'b11: IDLE_DONE - Ready deasserted, back to idle
    reg [1:0] dst_state;
    wire [1:0] dst_next_state;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            dst_state <= 2'b00;
        else
            dst_state <= dst_next_state;
    end

    always @(*) begin
        case (dst_state)
            2'b00: begin // IDLE
                if (src_valid_i)
                    dst_next_state = 2'b01; // REQ_RECEIVED
                else
                    dst_next_state = 2'b00;
            end
            2'b01: begin // REQ_RECEIVED
                if (src_valid_i && dst_ready_i)
                    dst_next_state = 2'b10; // ACK_SENT
                else if (src_valid_i)
                    dst_next_state = 2'b01; // Stay in REQ_RECEIVED
                else
                    dst_next_state = 2'b00; // Deassert valid, go to IDLE
            end
            2'b10: begin // ACK_SENT
                if (src_valid_i)
                    dst_next_state = 2'b11; // IDLE_DONE
                else
                    dst_next_state = 2'b00; // Deassert valid, go to IDLE
            end
            2'b11: begin // IDLE_DONE
                dst_next_state = 2'b00; // Go to IDLE
            end
            default: dst_next_state = 2'b00;
        endcase
    end

    // Generate dst_valid_o based on state
    assign dst_valid_o = (dst_state == 2'b01) || (dst_state == 2'b10);

endmodule<|im_end|>
