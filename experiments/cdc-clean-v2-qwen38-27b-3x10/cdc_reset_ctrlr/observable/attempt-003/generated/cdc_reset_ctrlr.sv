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

    // State encoding
    localparam S_IDLE     = 3'd0;
    localparam S_ISOLATE  = 3'd1;
    localparam S_CLEAR    = 3'd2;
    localparam S_RELEASE  = 3'd3;

    // A-side state
    reg [2:0] a_state;
    reg       a_isolate_o_r;
    reg       a_clear_o_r;

    // B-side state
    reg [2:0] b_state;
    reg       b_isolate_o_r;
    reg       b_clear_o_r;

    // A-side synchronized B-side status
    reg [2:0] b_state_sync_a;
    reg [2:0] b_state_sync_a_d1;
    reg [2:0] b_state_sync_a_d2;

    // B-side synchronized A-side status
    reg [2:0] a_state_sync_b;
    reg [2:0] a_state_sync_b_d1;
    reg [2:0] a_state_sync_b_d2;

    // Synchronize B state into A domain
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            b_state_sync_a_d1 <= 3'd0;
            b_state_sync_a_d2 <= 3'd0;
        end else begin
            b_state_sync_a_d1 <= b_state;
            b_state_sync_a_d2 <= b_state_sync_a_d1;
        end
    end
    assign b_state_sync_a = b_state_sync_a_d2;

    // Synchronize A state into B domain
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            a_state_sync_b_d1 <= 3'd0;
            a_state_sync_b_d2 <= 3'd0;
        end else begin
            a_state_sync_b_d1 <= a_state;
            a_state_sync_b_d2 <= a_state_sync_b_d1;
        end
    end
    assign a_state_sync_b = a_state_sync_b_d2;

    // A-side FSM
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_state       <= S_IDLE;
            a_isolate_o_r <= 1'b0;
            a_clear_o_r   <= 1'b0;
        end else begin
            case (a_state)
                S_IDLE: begin
                    if (a_clear_i || b_clear_i) begin
                        a_state       <= S_ISOLATE;
                        a_isolate_o_r <= 1'b1;
                        a_clear_o_r   <= 1'b0;
                    end
                end
                S_ISOLATE: begin
                    // Wait for both sides to acknowledge isolation
                    if (a_isolate_ack_i && b_isolate_ack_i) begin
                        a_state       <= S_CLEAR;
                        a_isolate_o_r <= 1'b1;
                        a_clear_o_r   <= 1'b1;
                    end
                end
                S_CLEAR: begin
                    // Wait for both sides to acknowledge clear
                    if (a_clear_ack_i && b_clear_ack_i) begin
                        a_state       <= S_RELEASE;
                        a_isolate_o_r <= 1'b1;
                        a_clear_o_r   <= 1'b0;
                    end
                end
                S_RELEASE: begin
                    // Wait for both sides to acknowledge release
                    if (a_isolate_ack_i && b_isolate_ack_i) begin
                        a_state       <= S_IDLE;
                        a_isolate_o_r <= 1'b0;
                        a_clear_o_r   <= 1'b0;
                    end
                end
                default: begin
                    a_state       <= S_IDLE;
                    a_isolate_o_r <= 1'b0;
                    a_clear_o_r   <= 1'b0;
                end
            endcase
        end
    end

    // B-side FSM
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_state       <= S_IDLE;
            b_isolate_o_r <= 1'b0;
            b_clear_o_r   <= 1'b0;
        end else begin
            case (b_state)
                S_IDLE: begin
                    if (a_clear_i || b_clear_i) begin
                        b_state       <= S_ISOLATE;
                        b_isolate_o_r <= 1'b1;
                        b_clear_o_r   <= 1'b0;
                    end
                end
                S_ISOLATE: begin
                    // Wait for both sides to acknowledge isolation
                    if (a_isolate_ack_i && b_isolate_ack_i) begin
                        b_state       <= S_CLEAR;
                        b_isolate_o_r <= 1'b1;
                        b_clear_o_r   <= 1'b1;
                    end
                end
                S_CLEAR: begin
                    // Wait for both sides to acknowledge clear
                    if (a_clear_ack_i && b_clear_ack_i) begin
                        b_state       <= S_RELEASE;
                        b_isolate_o_r <= 1'b1;
                        b_clear_o_r   <= 1'b0;
                    end
                end
                S_RELEASE: begin
                    // Wait for both sides to acknowledge release
                    if (a_isolate_ack_i && b_isolate_ack_i) begin
                        b_state       <= S_IDLE;
                        b_isolate_o_r <= 1'b0;
                        b_clear_o_r   <= 1'b0;
                    end
                end
                default: begin
                    b_state       <= S_IDLE;
                    b_isolate_o_r <= 1'b0;
                    b_clear_o_r   <= 1'b0;
                end
            endcase
        end
    end

    assign a_isolate_o = a_isolate_o_r;
    assign a_clear_o   = a_clear_o_r;
    assign b_isolate_o = b_isolate_o_r;
    assign b_clear_o   = b_clear_o_r;

endmodule
