module cdc_reset_ctrlr #(
    parameter SYNC_STAGES = 2
)(
    input  a_clk_i,
    input  a_rst_ni,
    input  a_clear_i,
    output reg a_clear_o,
    input  a_clear_ack_i,
    output reg a_isolate_o,
    input  a_isolate_ack_i,
    input  b_clk_i,
    input  b_rst_ni,
    input  b_clear_i,
    output reg b_clear_o,
    input  b_clear_ack_i,
    output reg b_isolate_o,
    input  b_isolate_ack_i
);

// State definitions
localparam [2:0] IDLE      = 3'd0,
                 ISOLATE   = 3'd1,
                 CLEAR_A   = 3'd2,
                 CLEAR_B   = 3'd3,
                 DEISOLATE = 3'd4;

// A domain signals
reg [2:0] state_a;
reg [SYNC_STAGES-1:0] sync_b_clear_i;
reg [SYNC_STAGES-1:0] sync_b_clear_ack_i;

// B domain signals
reg [2:0] state_b;
reg [SYNC_STAGES-1:0] sync_a_clear_i;
reg [SYNC_STAGES-1:0] sync_a_clear_ack_i;

// Synchronize B's clear_i and ack to A domain
always @(posedge a_clk_i or negedge a_rst_ni) begin
    if (!a_rst_ni) begin
        sync_b_clear_i <= 0;
        sync_b_clear_ack_i <= 0;
    end else begin
        sync_b_clear_i <= {sync_b_clear_i[SYNC_STAGES-2:0], b_clear_i};
        sync_b_clear_ack_i <= {sync_b_clear_ack_i[SYNC_STAGES-2:0], b_clear_ack_i};
    end
end

// A domain state machine
always @(posedge a_clk_i or negedge a_rst_ni) begin
    if (!a_rst_ni) begin
        state_a <= IDLE;
        a_isolate_o <= 0;
        a_clear_o <= 1;
        b_clear_o <= 1;
    end else begin
        case (state_a)
            IDLE: begin
                if (!a_clear_i || !sync_b_clear_i[SYNC_STAGES-1]) begin
                    state_a <= ISOLATE;
                    a_isolate_o <= 1;
                    b_isolate_o <= 1;
                end
            end
            ISOLATE: begin
                if (a_isolate_ack_i && b_isolate_ack_i) begin
                    state_a <= CLEAR_A;
                    a_clear_o <= 0;
                end
            end
            CLEAR_A: begin
                if (a_clear_ack_i) begin
                    state_a <= CLEAR_B;
                    a_clear_o <= 1;
                end
            end
            CLEAR_B: begin
                if (sync_b_clear_ack_i[SYNC_STAGES-1]) begin
                    state_a <= DEISOLATE;
                    b_clear_o <= 0;
                end
            end
            DEISOLATE: begin
                if (a_isolate_ack_i && b_isolate_ack_i) begin
                    a_isolate_o <= 0;
                    b_isolate_o <= 0;
                    state_a <= IDLE;
                end
            end
            default: state_a <= IDLE;
        endcase
    end
end

// Synchronize A's clear_i and ack to B domain
always @(posedge b_clk_i or negedge b_rst_ni) begin
    if (!b_rst_ni) begin
        sync_a_clear_i <= 0;
        sync_a_clear_ack_i <= 0;
    end else begin
        sync_a_clear_i <= {sync_a_clear_i[SYNC_STAGES-2:0], a_clear_i};
        sync_a_clear_ack_i <= {sync_a_clear_ack_i[SYNC_STAGES-2:0], a_clear_ack_i};
    end
end

// B domain state machine
always @(posedge b_clk_i or negedge b_rst_ni) begin
    if (!b_rst_ni) begin
        state_b <= IDLE;
        b_isolate_o <= 0;
        b_clear_o <= 1;
    end else begin
        case (state_b)
            IDLE: begin
                if (!sync_a_clear_i[SYNC_STAGES-1] || !b_clear_i) begin
                    state_b <= ISOLATE;
                    b_isolate_o <= 1;
                end
            end
            ISOLATE: begin
                if (a_isolate_ack_i && b_isolate_ack_i) begin
                    state_b <= CLEAR_B;
                    b_clear_o <= 0;
                end
            end
            CLEAR_B: begin
                if (b_clear_ack_i) begin
                    state_b <= DEISOLATE;
                    b_clear_o <= 1;
                end
            end
            DEISOLATE: begin
                if (a_isolate_ack_i && b_isolate_ack_i) begin
                    b_isolate_o <= 0;
                    state_b <= IDLE;
                end
            end
            default: state_b <= IDLE;
        endcase
    end
end

endmodule
