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

    // State encoding: 0=Idle, 1=Sent_Valid, 2=Sent_Ready, 3=Sent_Valid_Again
    parameter IDLE = 2'b00;
    parameter SENT_VALID = 2'b01;
    parameter SENT_READY = 2'b10;
    parameter SENT_VALID_AGAIN = 2'b11;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_state <= IDLE;
            src_valid_reg <= 1'b0;
            src_ready_o <= 1'b0;
        end else begin
            case (src_state)
                IDLE: begin
                    if (src_valid_i)
                        src_state <= SENT_VALID;
                    src_valid_reg <= 1'b0;
                    src_ready_o <= 1'b0;
                end
                SENT_VALID: begin
                    src_valid_reg <= 1'b1;
                    src_ready_o <= 1'b0;
                    if (src_valid_i)
                        src_state <= SENT_READY;
                end
                SENT_READY: begin
                    src_ready_o <= 1'b1;
                    if (src_valid_i)
                        src_state <= SENT_VALID_AGAIN;
                end
                SENT_VALID_AGAIN: begin
                    src_valid_reg <= 1'b1;
                    src_ready_o <= 1'b0;
                    if (src_valid_i)
                        src_state <= IDLE;
                    else
                        src_state <= SENT_VALID;
                end
                default: begin
                    src_state <= IDLE;
                    src_valid_reg <= 1'b0;
                    src_ready_o <= 1'b0;
                end
            endcase
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_state <= IDLE;
            dst_valid_reg <= 1'b0;
            dst_ready_reg <= 1'b0;
        end else begin
            case (dst_state)
                IDLE: begin
                    if (dst_ready_i)
                        dst_state <- SENT_VALID;
                    dst_valid_reg <= 1'b0;
                    dst_ready_reg <= 1'b0;
                end
                SENT_VALID: begin
                    dst_valid_reg <= 1'b1;
                    dst_ready_reg <= 1'b0;
                    if (dst_ready_i)
                        dst_state <= SENT_READY;
                end
                SENT_READY: begin
                    dst_ready_reg <= 1'b1;
                    if (dst_ready_i)
                        dst_state <= SENT_VALID_AGAIN;
                end
                SENT_VALID_AGAIN: begin
                    dst_valid_reg <= 1'b1;
                    dst_ready_reg <= 1'b0;
                    if (dst_ready_i)
                        dst_state <= IDLE;
                    else
                        dst_state <= SENT_VALID;
                end
                default: begin
                    dst_state <= IDLE;
                    dst_valid_reg <= 1'b0;
                    dst_ready_reg <= 1'b0;
                end
            endcase
        end
    end

    assign dst_valid_o = dst_valid_reg;
    assign src_ready_o = src_ready_o;

endmodule<|im_end|>
