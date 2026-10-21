```verilog
module cdc_reset_ctrlr #(
    parameter SYNC_STAGES = 2
)(
    input  a_clk_i,
    input  a_rst_ni,
    input  a_clear_i,
    output a_clear_o,
    input  a_clear_ack_i,
    output a_isolate_o,
    input  a_isolate_ack_i,
    input  b_clk_i,
    input  b_rst_ni,
    input  b_clear_i,
    output b_clear_o,
    input  b_clear_ack_i,
    output b_isolate_o,
    input  b_isolate_ack_i
);

    // Internal state machine states
    typedef enum logic [1:0] {
        IDLE,
        REQ_ISOLATE,
        ISOLATING,
        REQ_CLEAR,
        CLEARING,
        DONE
    } state_t;

    state_t state_a, state_b;
    state_t next_state_a, next_state_b;

    // Local request signals (active high)
    logic req_isolate_a, req_clear_a;
    logic req_isolate_b, req_clear_b;

    // Cross-domain signals (synchronous to local clock)
    logic cross_req_isolate_a, cross_req_clear_a;
    logic cross_req_isolate_b, cross_req_clear_b;
    logic cross_ack_isolate_a, cross_ack_clear_a;
    logic cross_ack_isolate_b, cross_ack_clear_b;

    // CDC registers for cross-domain requests
    logic [SYNC_STAGES-1:0] req_isolate_a_reg, req_clear_a_reg;
    logic [SYNC_STAGES-1:0] req_isolate_b_reg, req_clear_b_reg;
    logic [SYNC_STAGES-1:0] ack_isolate_a_reg, ack_clear_a_reg;
    logic [SYNC_STAGES-1:0] ack_isolate_b_reg, ack_clear_b_reg;

    // CDC registers for cross-domain acks
    logic [SYNC_STAGES-1:0] ack_isolate_a_reg, ack_clear_a_reg;
    logic [SYNC_STAGES-1:0] ack_isolate_b_reg, ack_clear_b_reg;

    // Output registers
    reg a_clear_o_reg, a_isolate_o_reg;
    reg b_clear_o_reg, b_isolate_o_reg;

    // Synchronous logic for cross-domain signals
    always_ff @(posedge a_clk_i or posedge a_rst_ni) begin
        if (a_rst_ni) begin
            req_isolate_a_reg <= '{default:0};
            req_clear_a_reg <= '{default:0};
            ack_isolate_a_reg <= '{default:0};
            ack_clear_a_reg <= '{default:0};
        end else begin
            req_isolate_a_reg <= {req_isolate_a_reg[SYNC_STAGES-2:0], a_clear_i};
            req_clear_a_reg <= {req_clear_a_reg[SYNC_STAGES-2:0], a_clear_i};
            ack_isolate_a_reg <= {ack_isolate_a_reg[SYNC_STAGES-2:0], a_isolate_ack_i};
            ack_clear_a_reg <= {ack_clear_a_reg[SYNC_STAGES-2:0], a_clear_ack_i};
        end
    end

    always_ff @(posedge b_clk_i or posedge b_rst_ni) begin
        if (b_rst_ni) begin
            req_isolate_b_reg <= '{default:0};
            req_clear_b_reg <= '{default:0};
            ack_isolate_b_reg <= '{default:0};
            ack_clear_b_reg <= '{default:0};
        end else begin
            req_isolate_b_reg <= {req_isolate_b_reg[SYNC_STAGES-2:0], b_clear_i};
            req_clear_b_reg <= {req_clear_b_reg[SYNC_STAGES-2:0], b_clear_i};
            ack_isolate_b_reg <= {ack_isolate_b_reg[SYNC_STAGES-2:0], b_isolate_ack_i};
            ack_clear_b_reg <= {ack_clear_b_reg[SYNC_STAGES-2:0], b_clear_ack_i};
        end
    end

    // State machine logic for Domain A
    always_ff @(posedge a_clk_i or posedge a_rst_ni) begin
        if (a_rst_ni) begin
            state_a <= IDLE;
            next_state_a <= IDLE;
        end else begin
            next_state_a <= state_a;
            case (state_a)
                IDLE: begin
                    if (req_isolate_a_reg[0]) next_state_a <- REQ_ISOLATE;
                    else if (req_clear_a_reg[0]) next_state_a <- REQ_CLEAR;
                    else next_state_a <- IDLE;
                end
                REQ_ISOLATE: begin
                    if (ack_isolate_a_reg[0]) next_state_a <- ISOLATING;
                    else next_state_a <- REQ_ISOLATE;
                end
                ISOLATING: begin
                    if (ack_isolate_a_reg[0]) next_state_a <- REQ_CLEAR;
                    else next_state_a <- ISOLATING;
                end
                REQ_CLEAR: begin
                    if (ack_clear_a_reg[0]) next_state_a <- CLEARING;
                    else next_state_a <- REQ_CLEAR;
                end
                CLEARING: begin
                    if (ack_clear_a_reg[0]) next_state_a <- DONE;
                    else next_state_a <- CLEARING;
                end
                DONE: begin
                    if (req_isolate_a_reg[0]) next_state_a <- REQ_ISOLATE;
                    else if (req_clear_a_reg[0]) next_state_a <- REQ_CLEAR;
                    else next_state_a <- IDLE;
                end
                default: next_state_a <- IDLE;
            endcase
        end
    end

    // State machine logic for Domain B
    always_ff @(posedge b_clk_i or posedge b_rst_ni) begin
        if (b_rst_ni) begin
            state_b <= IDLE;
            next_state_b <= IDLE;
        end else begin
            next_state_b <= state_b;
            case (state_b)
                IDLE: begin
                    if (req_isolate_b_reg[0]) next_state_b <- REQ_ISOLATE;
                    else if (req_clear_b_reg[0]) next_state_b <- REQ_CLEAR;
                    else next_state_b <- IDLE;
                end
                REQ_ISOLATE: begin
                    if (ack_isolate_b_reg[0]) next_state_b <- ISOLATING;
                    else next_state_b <- REQ_ISOLATE;
                end
                ISOLATING: begin
                    if (ack_isolate_b_reg[0]) next_state_b <- REQ_CLEAR;
                    else next_state_b <- ISOLATING;
                end
                REQ_CLEAR: begin
                    if (ack_clear_b_reg[0]) next_state_b <- CLEARING;
                    else next_state_b <- REQ_CLEAR;
                end
                CLEARING: begin
                    if (ack_clear_b_reg[0]) next_state_b <- DONE;
                    else next_state_b <- CLEARING;
                end
                DONE: begin
                    if (req_isolate_b_reg[0]) next_state_b <- REQ_ISOLATE;
                    else if (req_clear_b_reg[0]) next_state_b <- REQ_CLEAR;
                    else next_state_b <- IDLE;
                end
                default: next_state_b <- IDLE;
            endcase
        end
    end

    // Output logic for Domain A
    always_ff @(posedge a_clk_i or posedge a_rst_ni) begin
        if (a_rst_ni) begin
            a_clear_o_reg <= 1'b1;
            a_isolate_o_reg <= 1'b1;
        end else begin
            case (state_a)
                IDLE: begin
                    a_clear_o_reg <= 1'b1;
                    a_isolate_o_reg <= 1'b1;
                end
                REQ_ISOLATE: begin
                    a_clear_o_reg <= 1'b1;
                    a_isolate_o_reg <= 1'b0;
                end
                ISOLATING: begin
                    a_clear_o_reg <= 1'b1;
                    a_isolate_o_reg <= 1'b0;
                end
                REQ_CLEAR: begin
                    a_clear_o_reg <= 1'b0;
                    a_isolate_o_reg <= 1'b0;
                end
                CLEARING: begin
                    a_clear_o_reg <= 1'b0;
                    a_isolate_o_reg <= 1'b0;
                end
                DONE: begin
                    a_clear_o_reg <= 1'b1;
                    a_isolate_o_reg <= 1'b1;
                end
                default: begin
                    a_clear_o_reg <= 1'b1;
                    a_isolate_o_reg <= 1'b1;
                end
            endcase
        end
    end

    // Output logic for Domain B
    always_ff @(posedge b_clk_i or posedge b_rst_ni) begin
        if (b_rst_ni) begin
            b_clear_o_reg <= 1'b1;
            b_isolate_o_reg <= 1'b1;
        end else begin
            case (state_b)
                IDLE: begin
                    b_clear_o_reg <= 1'b1;
                    b_isolate_o_reg <= 1'b1;
                end
                REQ_ISOLATE: begin
                    b_clear_o_reg <= 1'b1;
                    b_isolate_o_reg <= 1'b0;
                end
                ISOLATING: begin
                    b_clear_o_reg <= 1'b1;
                    b_isolate_o_reg <= 1'b0;
                end
                REQ_CLEAR: begin
                    b_clear_o_reg <= 1'b0;
                    b_isolate_o_reg <= 1'b0;
                end
                CLEARING: begin
                    b_clear_o_reg <= 1'b0;
                    b_isolate_o_reg <= 1'b0;
                end
                DONE: begin
                    b_clear_o_reg <= 1'b1;
                    b_isolate_o_reg <= 1'b1;
                end
                default: begin
                    b_clear_o_reg <= 1'b1;
                    b_isolate_o_reg <= 1'b1;
                end
            endcase
        end
    end

    // Assign outputs
    assign a_clear_o = a_clear_o_reg;
    assign a_isolate_o = a_isolate_o_reg;
    assign b_clear_o = b_clear_o_reg;
    assign b_isolate_o = b_isolate_o_reg;

endmodule
```<|im_end|>
