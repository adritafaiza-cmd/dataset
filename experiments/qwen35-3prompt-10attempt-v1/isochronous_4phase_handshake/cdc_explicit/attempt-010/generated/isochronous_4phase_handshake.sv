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
    // 1. Use a 2-bit state machine in the source domain to generate a 4-phase handshake signal.
    //    States: IDLE(00), REQ(01), ACK(10), RESP(11).
    //    - src_valid_i triggers transition to REQ.
    //    - dst_ready_i (sampled in src domain) triggers transition to ACK.
    //    - src_ready_o is asserted during ACK and RESP phases.
    // 2. Use a 2-bit state machine in the destination domain to consume the handshake.
    //    States: IDLE(00), REQ(01), ACK(10), RESP(11).
    //    - dst_valid_i (sampled in dst domain) triggers transition to REQ.
    //    - src_ready_i (sampled in dst domain) triggers transition to ACK.
    //    - dst_valid_o is asserted during ACK and RESP phases.
    // 3. Reset release is handled synchronously in each domain.
    // 4. No multi-bit data transfer; only control signals are crossed, ensuring coherence.

    // Source Domain State Machine
    // State encoding: 2 bits
    // 00: IDLE
    // 01: REQ (Waiting for dst_ready)
    // 10: ACK (Handshake acknowledged, src_ready asserted)
    // 11: RESP (Response phase, src_ready asserted)
    reg [1:0] src_state;
    reg [1:0] src_next_state;
    reg src_valid_reg;

    // Destination Domain State Machine
    // State encoding: 2 bits
    // 00: IDLE
    // 01: REQ (Waiting for src_ready)
    // 10: ACK (Handshake acknowledged, dst_valid asserted)
    // 11: RESP (Response phase, dst_valid asserted)
    reg [1:0] dst_state;
    reg [1:0] dst_next_state;
    reg dst_valid_reg;

    // Source Domain Logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            src_state <= 2'b00;
        else
            src_state <= src_next_state;
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            src_valid_reg <= 1'b0;
        else
            src_valid_reg <= src_valid_i;
    end

    always @(*) begin
        src_next_state = src_state;
        case (src_state)
            2'b00: begin // IDLE
                if (src_valid_reg)
                    src_next_state = 2'b01; // REQ
                else
                    src_next_state = 2'b00;
            end
            2'b01: begin // REQ
                if (src_valid_reg && dst_ready_i)
                    src_next_state = 2'b10; // ACK
                else
                    src_next_state = 2'b01;
            end
            2'b10: begin // ACK
                src_next_state = 2'b11; // RESP
            end
            2'b11: begin // RESP
                if (src_valid_reg && dst_ready_i)
                    src_next_state = 2'b00; // Back to IDLE
                else
                    src_next_state = 2'b11;
            end
            default: src_next_state = 2'b00;
        endcase
    end

    // Output logic for source domain
    assign src_ready_o = (src_state == 2'b10) || (src_state == 2'b11);

    // Destination Domain Logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            dst_state <= 2'b00;
        else
            dst_state <= dst_next_state;
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            dst_valid_reg <= 1'b0;
        else
            dst_valid_reg <= dst_valid_i;
    end

    always @(*) begin
        dst_next_state = dst_state;
        case (dst_state)
            2'b00: begin // IDLE
                if (dst_valid_reg)
                    dst_next_state = 2'b01; // REQ
                else
                    dst_next_state = 2'b00;
            end
            2'b01: begin // REQ
                if (dst_valid_reg && src_ready_o)
                    dst_next_state = 2'b10; // ACK
                else
                    dst_next_state = 2'b01;
            end
            2'b10: begin // ACK
                dst_next_state = 2'b11; // RESP
            end
            2'b11: begin // RESP
                if (dst_valid_reg && src_ready_o)
                    dst_next_state = 2'b00; // Back to IDLE
                else
                    dst_next_state = 2'b11;
            end
            default: dst_next_state = 2'b00;
        endcase
    end

    // Output logic for destination domain
    assign dst_valid_o = (dst_state == 2'b10) || (dst_state == 2'b11);

endmodule<|im_end|>
