// Copyright 2021 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51.
// Verilog-2001 lock-step isolate/clear sequencer matching cdc_reset_ctrlr ports.

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

    localparam IDLE = 2'd0;
    localparam ISOLATE = 2'd1;
    localparam CLEAR = 2'd2;
    localparam WAIT_PEER = 2'd3;

    reg [1:0] a_state, b_state;
    reg a_holdoff, b_holdoff;
    reg a_peer_req_q, b_peer_req_q;
    (* ASYNC_REG = "TRUE" *) reg [SYNC_STAGES-1:0] a2b_req_sync, b2a_req_sync;
    (* ASYNC_REG = "TRUE" *) reg [SYNC_STAGES-1:0] a2b_done_sync, b2a_done_sync;

    wire a_req = (a_state != IDLE);
    wire b_req = (b_state != IDLE);
    wire a_done = (a_state == WAIT_PEER);
    wire b_done = (b_state == WAIT_PEER);
    wire a_peer_req = b2a_req_sync[SYNC_STAGES-1];
    wire b_peer_req = a2b_req_sync[SYNC_STAGES-1];
    wire a_peer_done = b2a_done_sync[SYNC_STAGES-1];
    wire b_peer_done = a2b_done_sync[SYNC_STAGES-1];
    wire a_start = (a_clear_i || (a_peer_req && !a_peer_req_q)) && !a_holdoff;
    wire b_start = (b_clear_i || (b_peer_req && !b_peer_req_q)) && !b_holdoff;

    assign a_isolate_o = (a_state != IDLE);
    assign a_clear_o   = (a_state == CLEAR);
    assign b_isolate_o = (b_state != IDLE);
    assign b_clear_o   = (b_state == CLEAR);

    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_state <= IDLE;
            a_holdoff <= 1'b0;
            a_peer_req_q <= 1'b0;
            b2a_req_sync <= {SYNC_STAGES{1'b0}};
            b2a_done_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            a_peer_req_q <= a_peer_req;
            b2a_req_sync <= {b2a_req_sync[SYNC_STAGES-2:0], b_req};
            b2a_done_sync <= {b2a_done_sync[SYNC_STAGES-2:0], b_done};
            if (!a_peer_req)
                a_holdoff <= 1'b0;
            case (a_state)
                IDLE: if (a_start) a_state <= ISOLATE;
                ISOLATE: if (a_isolate_ack_i) a_state <= CLEAR;
                CLEAR: if (a_clear_ack_i) a_state <= WAIT_PEER;
                WAIT_PEER: if (a_peer_done) begin
                    a_state <= IDLE;
                    a_holdoff <= 1'b1;
                end
                default: a_state <= IDLE;
            endcase
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_state <= IDLE;
            b_holdoff <= 1'b0;
            b_peer_req_q <= 1'b0;
            a2b_req_sync <= {SYNC_STAGES{1'b0}};
            a2b_done_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            b_peer_req_q <= b_peer_req;
            a2b_req_sync <= {a2b_req_sync[SYNC_STAGES-2:0], a_req};
            a2b_done_sync <= {a2b_done_sync[SYNC_STAGES-2:0], a_done};
            if (!b_peer_req)
                b_holdoff <= 1'b0;
            case (b_state)
                IDLE: if (b_start) b_state <= ISOLATE;
                ISOLATE: if (b_isolate_ack_i) b_state <= CLEAR;
                CLEAR: if (b_clear_ack_i) b_state <= WAIT_PEER;
                WAIT_PEER: if (b_peer_done) begin
                    b_state <= IDLE;
                    b_holdoff <= 1'b1;
                end
                default: b_state <= IDLE;
            endcase
        end
    end

endmodule
