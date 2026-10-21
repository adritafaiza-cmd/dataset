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

    // ------------------------------------------------------------------
    // CDC Logic for Signals crossing from Domain A to Domain B
    // ------------------------------------------------------------------
    wire [SYNC_STAGES-1:0] a_clear_req_cdc;
    wire [SYNC_STAGES-1:0] a_clear_ack_cdc;
    wire [SYNC_STAGES-1:0] a_isolate_req_cdc;
    wire [SYNC_STAGES-1:0] a_isolate_ack_cdc;
    wire [SYNC_STAGES-1:0] b_clear_req_cdc;
    wire [SYNC_STAGES-1:0] b_clear_ack_cdc;
    wire [SYNC_STAGES-1:0] b_isolate_req_cdc;
    wire [SYNC_STAGES-1:0] b_isolate_ack_cdc;

    // CDC from A to B (A signals -> B domain)
    genvar i;
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_cdc_a_to_b
            if (i == 0) begin
                assign a_clear_req_cdc[i]   = a_clear_i;
                assign a_clear_ack_cdc[i]   = a_clear_ack_i;
                assign a_isolate_req_cdc[i] = a_isolate_o;
                assign a_isolate_ack_cdc[i] = a_isolate_ack_i;
            end else begin
                assign a_clear_req_cdc[i]   = a_clear_req_cdc[i-1];
                assign a_clear_ack_cdc[i]   = a_clear_ack_cdc[i-1];
                assign a_isolate_req_cdc[i] = a_isolate_req_cdc[i-1];
                assign a_isolate_ack_cdc[i] = a_isolate_ack_cdc[i-1];
            end
        end
    endgenerate

    // CDC from B to A (B signals -> A domain)
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_cdc_b_to_a
            if (i == 0) begin
                assign b_clear_req_cdc[i]   = b_clear_i;
                assign b_clear_ack_cdc[i]   = b_clear_ack_i;
                assign b_isolate_req_cdc[i] = b_isolate_o;
                assign b_isolate_ack_cdc[i] = b_isolate_ack_i;
            end else begin
                assign b_clear_req_cdc[i]   = b_clear_req_cdc[i-1];
                assign b_clear_ack_cdc[i]   = b_clear_ack_cdc[i-1];
                assign b_isolate_req_cdc[i] = b_isolate_req_cdc[i-1];
                assign b_isolate_ack_cdc[i] = b_isolate_ack_cdc[i-1];
            end
        end
    endgenerate

    // ------------------------------------------------------------------
    // State Machine Logic (Implemented in both domains)
    // ------------------------------------------------------------------
    // States:
    // IDLE: Normal operation, no isolation or clear active.
    // ISOLATE_A: Domain A is isolating, waiting for B to acknowledge isolation.
    // ISOLATE_B: Domain B is isolating, waiting for A to acknowledge isolation.
    // ISOLATE_BOTH: Both sides isolated, waiting for both to acknowledge.
    // CLEAR_A: A is clearing, waiting for B ack clear.
    // CLEAR_B: B is clearing, waiting for A ack clear.
    // CLEAR_BOTH: Both clearing, waiting for both ack clear.
    // DONE: Reset sequence complete, returning to IDLE.

    // Local state registers
    reg [2:0] state_a, state_b;
    reg [2:0] next_state_a, next_state_b;

    // Local control signals
    reg a_isolate_local;
    reg b_isolate_local;
    reg a_clear_local;
    reg b_clear_local;

    // ------------------------------------------------------------------
    // Domain A State Machine
    // ------------------------------------------------------------------
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            state_a <= 3'd0; // IDLE
            a_isolate_local <= 1'b0;
            a_clear_local <= 1'b0;
        end else begin
            state_a <= next_state_a;
            a_isolate_local <= (state_a == 3'd1) || (state_a == 3'd2) || (state_a == 3'd3);
            a_clear_local <= (state_a == 3'd4) || (state_a == 3'd5) || (state_a == 3'd6);
        end
    end

    always @(*) begin
        next_state_a = state_a;
        a_isolate_o = 1'b0;
        a_clear_o = 1'b1;

        case (state_a)
            3'd0: begin // IDLE
                if (a_clear_i) next_state_a = 3'd4; // Request Clear
                else if (b_clear_req_cdc[SYNC_STAGES-1]) next_state_a = 3'd2; // Peer requested clear
            end

            3'd1: begin // ISOLATE_A (A isolating, waiting for B ack)
                a_isolate_o = 1'b1;
                if (a_isolate_ack_i) next_state_a = 3'd3; // B ack received, move to isolate both
            end

            3'd2: begin // ISOLATE_B (B isolating, waiting for A ack)
                b_isolate_o = 1'b1;
                if (a_isolate_ack_i) next_state_a = 3'd3; // A ack received, move to isolate both
            end

            3'd3: begin // ISOLATE_BOTH (Both isolated, waiting for both acks)
                a_isolate_o = 1'b1;
                b_isolate_o = 1'b1;
                if (a_isolate_ack_i && b_isolate_ack_i) next_state_a = 3'd4; // Both acked, proceed to clear
            end

            3'd4: begin // CLEAR_A (A clearing, waiting for B ack)
                a_clear_o = 1'b0;
                if (a_clear_ack_i) next_state_a = 3'd6; // B ack received, move to clear both
            end

            3'd5: begin // CLEAR_B (B clearing, waiting for A ack)
                b_clear_o = 1'b0;
                if (a_clear_ack_i) next_state_a = 3'd6; // A ack received, move to clear both
            end

            3'd6: begin // CLEAR_BOTH (Both clearing, waiting for both acks)
                a_clear_o = 1'b0;
                b_clear_o = 1'b0;
                if (a_clear_ack_i && b_clear_ack_i) next_state_a = 3'd0; // Both acked, return to IDLE
            end

            default: next_state_a = 3'd0;
        endcase
    end

    // ------------------------------------------------------------------
    // Domain B State Machine
    // ------------------------------------------------------------------
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            state_b <= 3'd0; // IDLE
            b_isolate_local <= 1'b0;
            b_clear_local <= 1'b0;
        end else begin
            state_b <= next_state_b;
            b_isolate_local <= (state_b == 3'd1) || (state_b == 3'd2) || (state_b == 3'd3);
            b_clear_local <= (state_b == 3'd4) || (state_b == 3'd5) || (state_b == 3'd6);
        end
    end

    always @(*) begin
        next_state_b = state_b;
        b_isolate_o = 1'b0;
        b_clear_o = 1'b1;

        case (state_b)
            3'd0: begin // IDLE
                if (b_clear_i) next_state_b = 3'd4; // Request Clear
                else if (a_clear_req_cdc[SYNC_STAGES-1]) next_state_b = 3'd2; // Peer requested clear
            end

            3'd1: begin // ISOLATE_A (A isolating, waiting for B ack)
                a_isolate_o = 1'b1;
                if (b_isolate_ack_i) next_state_b = 3'd3; // A ack received, move to isolate both
            end

            3'd2: begin // ISOLATE_B (B isolating, waiting for A ack)
                b_isolate_o = 1'b1;
                if (b_isolate_ack_i) next_state_b = 3'd3; // A ack received, move to isolate both
            end

            3'd3: begin // ISOLATE_BOTH (Both isolated, waiting for both acks)
                a_isolate_o = 1'b1;
                b_isolate_o = 1'b1;
                if (a_isolate_ack_i && b_isolate_ack_i) next_state_b = 3'd4; // Both acked, proceed to clear
            end

            3'd4: begin // CLEAR_A (A clearing, waiting for B ack)
                a_clear_o = 1'b0;
                if (b_clear_ack_i) next_state_b = 3'd6; // A ack received, move to clear both
            end

            3'd5: begin // CLEAR_B (B clearing, waiting for A ack)
                b_clear_o = 1'b0;
                if (b_clear_ack_i) next_state_b = 3'd6; // A ack received, move to clear both
            end

            3'd6: begin // CLEAR_BOTH (Both clearing, waiting for both acks)
                a_clear_o = 1'b0;
                b_clear_o = 1'b0;
                if (a_clear_ack_i && b_clear_ack_i) next_state_b = 3'd0; // Both acked, return to IDLE
            end

            default: next_state_b = 3'd0;
        endcase
    end

    // ------------------------------------------------------------------
    // Output Drivers
    // ------------------------------------------------------------------
    assign a_isolate_o = a_isolate_local;
    assign b_isolate_o = b_isolate_local;
    assign a_clear_o = a_clear_local;
    assign b_clear_o = b_clear_local;

endmodule
```<|im_end|>
