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

    // State encoding for the 4-phase handshake
    // IDLE: Waiting for src_valid
    // REQ:   src_valid asserted, waiting for dst_ready
    // ACK:   dst_ready asserted, waiting for dst_valid
    // RSP:   dst_valid asserted, waiting for src_ready
    localparam [1:0] IDLE = 2'b00;
    localparam [1:0] REQ  = 2'b01;
    localparam [1:0] ACK  = 2'b10;
    localparam [1:0] RSP  = 2'b11;

    reg [1:0] src_state;
    reg [1:0] dst_state;

    // CDC-safe registers for crossing signals
    // src_domain signals to dst_domain
    reg dst_ready_d1;
    reg dst_valid_d1;
    reg dst_valid_d2;

    // dst_domain signals to src_domain
    reg src_valid_d1;
    reg src_ready_d1;
    reg src_ready_d2;

    // ------------------------------------------------------------------
    // Source Domain Logic
    // ------------------------------------------------------------------
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_state     <= IDLE;
            src_ready_o   <= 1'b0;
            src_valid_d1  <= 1'b0;
            src_ready_d1  <= 1'b0;
            src_ready_d2  <= 1'b0;
        end else begin
            // Capture destination signals safely
            src_valid_d1 <= dst_valid_d1;
            src_ready_d1 <= dst_ready_d1;
            src_ready_d2 <= dst_ready_d2;

            case (src_state)
                IDLE: begin
                    if (src_valid_i) begin
                        src_state <= REQ;
                        src_ready_o <= 1'b0;
                    end else begin
                        src_state <= IDLE;
                        src_ready_o <= 1'b0;
                    end
                end

                REQ: begin
                    if (src_valid_i && src_ready_d1) begin
                        src_state <= ACK;
                        src_ready_o <= 1'b0;
                    end else if (!src_valid_i) begin
                        src_state <= IDLE;
                        src_ready_o <= 1'b0;
                    end else begin
                        src_state <= REQ;
                        src_ready_o <= 1'b0;
                    end
                end

                ACK: begin
                    if (src_ready_d1) begin
                        src_state <= RSP;
                        src_ready_o <= 1'b1;
                    end else begin
                        src_state <= ACK;
                        src_ready_o <= 1'b0;
                    end
                end

                RSP: begin
                    if (src_ready_d1) begin
                        src_state <= IDLE;
                        src_ready_o <= 1'b0;
                    end else begin
                        src_state <= RSP;
                        src_ready_o <= 1'b1;
                    end
                end
            endcase
        end
    end

    // ------------------------------------------------------------------
    // Destination Domain Logic
    // ------------------------------------------------------------------
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_state     <= IDLE;
            dst_valid_o   <= 1'b0;
            dst_valid_d1  <= 1'b0;
            dst_valid_d2  <= 1'b0;
        end else begin
            // Capture source signals safely
            dst_valid_d1 <= src_valid_d1;
            dst_valid_d2 <= src_valid_d2;

            case (dst_state)
                IDLE: begin
                    if (dst_ready_i) begin
                        dst_state <= REQ;
                        dst_valid_o <= 1'b0;
                    end else begin
                        dst_state <= IDLE;
                        dst_valid_o <= 1'b0;
                    end
                end

                REQ: begin
                    if (dst_ready_i && dst_valid_d1) begin
                        dst_state <= ACK;
                        dst_valid_o <= 1'b0;
                    end else if (!dst_ready_i) begin
                        dst_state <= IDLE;
                        dst_valid_o <= 1'b0;
                    end else begin
                        dst_state <= REQ;
                        dst_valid_o <= 1'b0;
                    end
                end

                ACK: begin
                    if (dst_valid_d1) begin
                        dst_state <= RSP;
                        dst_valid_o <= 1'b1;
                    end else begin
                        dst_state <= ACK;
                        dst_valid_o <= 1'b0;
                    end
                end

                RSP: begin
                    if (dst_valid_d1) begin
                        dst_state <= IDLE;
                        dst_valid_o <= 1'b0;
                    end else begin
                        dst_state <= RSP;
                        dst_valid_o <= 1'b1;
                    end
                end
            endcase
        end
    end

    // ------------------------------------------------------------------
    // CDC Crossing: Destination -> Source (2-stage pipeline)
    // ------------------------------------------------------------------
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_valid_d1 <= 1'b0;
            dst_ready_d1 <= 1'b0;
            dst_valid_d2 <= 1'b0;
            dst_ready_d2 <= 1'b0;
        end else begin
            dst_valid_d1 <= dst_valid_o;
            dst_ready_d1 <= dst_ready_i;
            dst_valid_d2 <= dst_valid_d1;
            dst_ready_d2 <= dst_ready_d1;
        end
    end

    // ------------------------------------------------------------------
    // CDC Crossing: Source -> Destination (2-stage pipeline)
    // ------------------------------------------------------------------
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_valid_d1 <= 1'b0;
            src_ready_d1 <= 1'b0;
            src_valid_d2 <= 1'b0;
            src_ready_d2 <= 1'b0;
        end else begin
            src_valid_d1 <= src_valid_o;
            src_ready_d1 <= src_ready_i;
            src_valid_d2 <= src_valid_d1;
            src_ready_d2 <= src_ready_d1;
        end
    end

endmodule<|im_end|>
