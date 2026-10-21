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
    localparam STATE_ISOLATE = 2'b01;
    localparam STATE_CLEAR = 2'b10;
    localparam STATE_DONE = 2'b11;

    // ------------------------------------------------------------------
    // Domain A State Machine
    // ------------------------------------------------------------------
    reg [1:0] a_state, a_next_state;
    reg [1:0] a_peer_state; // Captures b's state via CDC

    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_state <= STATE_IDLE;
            a_peer_state <= 2'b00;
            a_clear_o <= 1'b0;
            a_isolate_o <= 1'b0;
        end else begin
            a_state <= a_next_state;
            a_peer_state <= a_peer_state; // Hold current observation
        end
    end

    always @(*) begin
        a_next_state = a_state;
        a_clear_o = 1'b0;
        a_isolate_o = 1'b0;

        case (a_state)
            STATE_IDLE: begin
                if (a_clear_i) begin
                    a_next_state = STATE_ISOLATE;
                    a_isolate_o = 1'b1;
                end
            end

            STATE_ISOLATE: begin
                // Wait for peer to enter ISOLATE and then CLEAR
                // We observe peer state. If peer is in CLEAR, we proceed.
                if (a_peer_state == STATE_CLEAR) begin
                    a_next_state = STATE_CLEAR;
                    a_clear_o = 1'b1;
                end
            end

            STATE_CLEAR: begin
                // Wait for peer to enter DONE
                if (a_peer_state == STATE_DONE) begin
                    a_next_state = STATE_DONE;
                    a_isolate_o = 1'b0;
                    a_clear_o = 1'b0;
                end
            end

            STATE_DONE: begin
                // Wait for peer to return to IDLE
                if (a_peer_state == STATE_IDLE) begin
                    a_next_state = STATE_IDLE;
                end
            end

            default: a_next_state = STATE_IDLE;
        endcase
    end

    // ------------------------------------------------------------------
    // Domain B State Machine
    // ------------------------------------------------------------------
    reg [1:0] b_state, b_next_state;
    reg [1:0] b_peer_state; // Captures a's state via CDC

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_state <= STATE_IDLE;
            b_peer_state <= 2'b00;
            b_clear_o <= 1'b0;
            b_isolate_o <= 1'b0;
        end else begin
            b_state <= b_next_state;
            b_peer_state <= b_peer_state; // Hold current observation
        end
    end

    always @(*) begin
        b_next_state = b_state;
        b_clear_o = 1'b0;
        b_isolate_o = 1'b0;

        case (b_state)
            STATE_IDLE: begin
                if (b_clear_i) begin
                    b_next_state = STATE_ISOLATE;
                    b_isolate_o = 1'b1;
                end
            end

            STATE_ISOLATE: begin
                if (b_peer_state == STATE_CLEAR) begin
                    b_next_state = STATE_CLEAR;
                    b_clear_o = 1'b1;
                end
            end

            STATE_CLEAR: begin
                if (b_peer_state == STATE_DONE) begin
                    b_next_state = STATE_DONE;
                    b_isolate_o = 1'b0;
                    b_clear_o = 1'b0;
                end
            end

            STATE_DONE: begin
                if (b_peer_state == STATE_IDLE) begin
                    b_next_state = STATE_IDLE;
                end
            end

            default: b_next_state = STATE_IDLE;
        endcase
    end

    // ------------------------------------------------------------------
    // CDC Crossing: Domain A -> Domain B (State Observation)
    // Uses Gray Code encoding for SYNC_STAGES to ensure single-bit transitions
    // ------------------------------------------------------------------
    reg [SYNC_STAGES:0] a_gray_reg;
    wire [SYNC_STAGES:0] a_gray_next;

    // Generate Gray Code from State
    always @(*) begin
        a_gray_next = 0;
        case (a_state)
            STATE_IDLE: a_gray_next = 1; // 00...01
            STATE_ISOLATE: a_gray_next = 2; // 00...11
            STATE_CLEAR: a_gray_next = 4; // 01...00 (Wait, standard Gray: 00, 01, 11, 10)
            // Let's use standard binary-reflected Gray code mapping for 2 states
            // 00 -> 00...00
            // 01 -> 00...01
            // 10 -> 00...10
            // 11 -> 00...11
            // Actually, for 4 states, we need 3 bits for Gray if we want strict single bit.
            // However, since we only transition between specific states, we can map:
            // IDLE(00) -> 000
            // ISOLATE(01) -> 001
            // CLEAR(10) -> 011
            // DONE(11) -> 111
            // Transitions: 00->001 (1 bit), 001->011 (1 bit), 011->111 (1 bit), 111->000 (1 bit).
            // This works perfectly for 2-bit state machine with 3-bit Gray register.
            
            if (a_state == STATE_IDLE) a_gray_next = 3'b000;
            else if (a_state == STATE_ISOLATE) a_gray_next = 3'b001;
            else if (a_state == STATE_CLEAR) a_gray_next = 3'b011;
            else if (a_state == STATE_DONE) a_gray_next = 3'b111;
            else a_gray_next = 3'b000;
        endcase
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni)
            a_gray_reg <= 0;
        else
            a_gray_reg <= a_gray_next;
    end

    // Decode Gray to State in Domain B
    always @(*) begin
        b_peer_state = 2'b00;
        if (a_gray_reg[0] == 1'b0 && a_gray_reg[1] == 1'b0 && a_gray_reg[2] == 1'b0)
            b_peer_state = STATE_IDLE;
        else if (a_gray_reg[0] == 1'b1 && a_gray_reg[1] == 1'b0 && a_gray_reg[2] == 1'b0)
            b_peer_state = STATE_ISOLATE;
        else if (a_gray_reg[0] == 1'b1 && a_gray_reg[1] == 1'b1 && a_gray_reg[2] == 1'b0)
            b_peer_state = STATE_CLEAR;
        else if (a_gray_reg[0] == 1'b1 && a_gray_reg[1] == 1'b1 && a_gray_reg[2] == 1'b1)
            b_peer_state = STATE_DONE;
    end

    // ------------------------------------------------------------------
    // CDC Crossing: Domain B -> Domain A (State Observation)
    // ------------------------------------------------------------------
    reg [SYNC_STAGES:0] b_gray_reg;
    wire [SYNC_STAGES:0] b_gray_next;

    always @(*) begin
        b_gray_next = 0;
        case (b_state)
            STATE_IDLE: b_gray_next = 3'b000;
            STATE_ISOLATE: b_gray_next = 3'b001;
            STATE_CLEAR: b_gray_next = 3'b011;
            STATE_DONE: b_gray_next = 3'b111;
            default: b_gray_next = 3'b000;
        endcase
    end

    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni)
            b_gray_reg <= 0;
        else
            b_gray_reg <= b_gray_next;
    end

    // Decode Gray to State in Domain A
    always @(*) begin
        a_peer_state = 2'b00;
        if (b_gray_reg[0] == 1'b0 && b_gray_reg[1] == 1'b0 && b_gray_reg[2] == 1'b0)
            a_peer_state = STATE_IDLE;
        else if (b_gray_reg[0] == 1'b1 && b_gray_reg[1] == 1'b0 && b_gray_reg[2] == 1'b0)
            a_peer_state = STATE_ISOLATE;
        else if (b_gray_reg[0] == 1'b1 && b_gray_reg[1] == 1'b1 && b_gray_reg[2] == 1'b0)
            a_peer_state = STATE_CLEAR;
        else if (b_gray_reg[0] == 1'b1 && b_gray_reg[1] == 1'b1 && b_gray_reg[2] == 1'b1)
            a_peer_state = STATE_DONE;
    end

endmodule
```<|im_end|>
