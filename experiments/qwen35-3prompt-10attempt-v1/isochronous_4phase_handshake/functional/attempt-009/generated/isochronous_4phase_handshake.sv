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

    reg src_state;
    reg dst_state;
    reg src_valid_reg;
    reg dst_valid_reg;
    reg dst_ready_reg;

    // State encoding: 0=Idle, 1=ValidSent, 2=ReadySent, 3=ValidAck
    parameter IDLE = 2'b00;
    parameter VALID_SENT = 2'b01;
    parameter READY_SENT = 2'b10;
    parameter VALID_ACK = 2'b11;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_state <= IDLE;
            src_valid_reg <= 1'b0;
            src_ready_o <= 1'b0;
        end else begin
            case (src_state)
                IDLE: begin
                    if (src_valid_i)
                        src_state <= VALID_SENT;
                    src_valid_reg <= 1'b0;
                    src_ready_o <= 1'b0;
                end
                VALID_SENT: begin
                    src_valid_reg <= 1'b1;
                    src_ready_o <= 1'b1;
                    if (dst_valid_reg)
                        src_state <= READY_SENT;
                    else
                        src_state <= IDLE;
                end
                READY_SENT: begin
                    src_ready_o <= 1'b0;
                    if (dst_valid_reg)
                        src_state <= VALID_ACK;
                    else
                        src_state <= IDLE;
                end
                VALID_ACK: begin
                    src_valid_reg <= 1'b0;
                    src_state <= IDLE;
                end
                default: begin
                    src_state <= IDLE;
                    src_valid_reg <= 1'b0;
                    src_ready_o <= 1'b0;
                end
            endcase
        end
    end

    // Destination side state machine
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_state <= IDLE;
            dst_valid_reg <= 1'b0;
            dst_ready_reg <= 1'b0;
        end else begin
            case (dst_state)
                IDLE: begin
                    if (dst_ready_i)
                        dst_state <- VALID_SENT;
                    dst_valid_reg <= 1'b0;
                    dst_ready_reg <= 1'b0;
                end
                VALID_SENT: begin
                    dst_valid_reg <= 1'b1;
                    dst_ready_reg <= 1'b1;
                    if (src_valid_reg)
                        dst_state <= READY_SENT;
                    else
                        dst_state <= IDLE;
                end
                READY_SENT: begin
                    dst_ready_reg <= 1'b0;
                    if (src_valid_reg)
                        dst_state <= VALID_ACK;
                    else
                        dst_state <= IDLE;
                end
                VALID_ACK: begin
                    dst_valid_reg <= 1'b0;
                    dst_state <= IDLE;
                end
                default: begin
                    dst_state <= IDLE;
                    dst_valid_reg <= 1'b0;
                    dst_ready_reg <= 1'b0;
                end
            endcase
        end
    end

    // Output assignments
    assign dst_valid_o = dst_valid_reg;
    assign src_ready_o = src_ready_o; // Already driven in FSM, but explicit for clarity

endmodule<|im_end|>
