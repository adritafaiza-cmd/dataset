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
            a_peer_state <= a_peer_state; // Hold previous observation
            // Output logic handled in combinational block below
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
                end
            end

            STATE_ISOLATE: begin
                a_isolate_o = 1'b1;
                if (a_isolate_ack_i && a_peer_state == STATE_DONE) begin
                    a_next_state = STATE_CLEAR;
                end
            end

            STATE_CLEAR: begin
                a_clear_o = 1'b1;
                if (a_clear_ack_i && a_peer_state == STATE_DONE) begin
                    a_next_state = STATE_DONE;
                end
            end

            STATE_DONE: begin
                if (a_clear_ack_i && a_peer_state == STATE_DONE) begin
                    a_next_state = STATE_IDLE;
                end
            end

            default: begin
                a_next_state = STATE_IDLE;
            end
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
            b_peer_state <= b_peer_state; // Hold previous observation
            // Output logic handled in combinational block below
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
                end
            end

            STATE_ISOLATE: begin
                b_isolate_o = 1'b1;
                if (b_isolate_ack_i && b_peer_state == STATE_DONE) begin
                    b_next_state = STATE_CLEAR;
                end
            end

            STATE_CLEAR: begin
                b_clear_o = 1'b1;
                if (b_clear_ack_i && b_peer_state == STATE_DONE) begin
                    b_next_state = STATE_DONE;
                end
            end

            STATE_DONE: begin
                if (b_clear_ack_i && b_peer_state == STATE_DONE) begin
                    b_next_state = STATE_IDLE;
                end
            end

            default: begin
                b_next_state = STATE_IDLE;
            end
        endcase
    end

    // ------------------------------------------------------------------
    // CDC Crossing Logic (Gray Code Synchronizers)
    // ------------------------------------------------------------------
    // Capture b_state in Domain A
    reg [1:0] b_state_gray;
    reg [1:0] b_state_synced;

    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni)
            b_state_synced <= 2'b00;
        else
            b_state_synced <= b_state_gray;
    end

    // Simple 2-stage synchronizer for b_state bits
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni)
            b_state_gray <= 2'b00;
        else
            b_state_gray <= {b_state[0], b_state[1]}; // Direct capture is unsafe, use sync chain
    end

    // Correct approach: Synchronize the 2-bit state vector
    // We need to synchronize each bit of b_state independently
    reg [1:0] b_state_sync_a_1, b_state_sync_a_2;
    reg [1:0] b_state_sync_b_1, b_state_sync_b_2;

    // Synchronize b_state[0]
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) b_state_sync_a_1 <= 1'b0;
        else b_state_sync_a_1 <= b_state[0];
    end
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) b_state_sync_a_2 <= 1'b0;
        else b_state_sync_a_2 <= b_state_sync_a_1;
    end

    // Synchronize b_state[1]
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) b_state_sync_b_1 <= 1'b0;
        else b_state_sync_b_1 <= b_state[1];
    end
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) b_state_sync_b_2 <= 1'b0;
        else b_state_sync_b_2 <= b_state_sync_b_1;
    end

    assign a_peer_state = {b_state_sync_b_2, b_state_sync_a_2};

    // Synchronize a_state in Domain B
    reg [1:0] a_state_sync_b_1, a_state_sync_b_2;
    reg [1:0] a_state_sync_a_1, a_state_sync_a_2;

    // Synchronize a_state[0]
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) a_state_sync_b_1 <= 1'b0;
        else a_state_sync_b_1 <= a_state[0];
    end
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) a_state_sync_b_2 <= 1'b0;
        else a_state_sync_b_2 <= a_state_sync_b_1;
    end

    // Synchronize a_state[1]
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) a_state_sync_a_1 <= 1'b0;
        else a_state_sync_a_1 <= a_state[1];
    end
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) a_state_sync_a_2 <= 1'b0;
        else a_state_sync_a_2 <= a_state_sync_a_1;
    end

    assign b_peer_state = {a_state_sync_a_2, a_state_sync_b_2};

endmodule
```<|im_end|>
