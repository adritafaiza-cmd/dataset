// Copyright 2021 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51.
// Verilog-2001 lock-step isolate/clear sequencer.
//
// The crossed status is a held 2-bit code, not a combinational
// decode into a synchronizer. Codes leave in order
// idle -> active -> done -> idle. A new code is launched only
// after the previous 2-phase transfer is acknowledged, so a
// one-cycle local transition cannot collapse two events into
// one sample. Local isolate and clear still advance on the
// local acknowledgments. Release waits until the sampled peer
// code is done.

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

    wire a_req, b_req;
    wire [1:0] a_data, b_data;
    wire a_ack, b_ack;

    cdc_reset_side #(.SYNC_STAGES(SYNC_STAGES)) i_a (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .clear_i(a_clear_i),
        .clear_ack_i(a_clear_ack_i),
        .isolate_ack_i(a_isolate_ack_i),
        .clear_o(a_clear_o),
        .isolate_o(a_isolate_o),
        .async_req_o(a_req),
        .async_data_o(a_data),
        .async_ack_i(a_ack),
        .async_peer_req_i(b_req),
        .async_peer_data_i(b_data),
        .async_peer_ack_o(b_ack)
    );

    cdc_reset_side #(.SYNC_STAGES(SYNC_STAGES)) i_b (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .clear_i(b_clear_i),
        .clear_ack_i(b_clear_ack_i),
        .isolate_ack_i(b_isolate_ack_i),
        .clear_o(b_clear_o),
        .isolate_o(b_isolate_o),
        .async_req_o(b_req),
        .async_data_o(b_data),
        .async_ack_i(b_ack),
        .async_peer_req_i(a_req),
        .async_peer_data_i(a_data),
        .async_peer_ack_o(a_ack)
    );

endmodule

module cdc_reset_side #(
    parameter SYNC_STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  clear_i,
    input  clear_ack_i,
    input  isolate_ack_i,
    output clear_o,
    output isolate_o,
    output async_req_o,
    output [1:0] async_data_o,
    input  async_ack_i,
    input  async_peer_req_i,
    input  [1:0] async_peer_data_i,
    output async_peer_ack_o
);

    localparam IDLE = 3'd0;
    localparam ISOLATE = 3'd1;
    localparam CLEAR = 3'd2;
    localparam WAIT_PEER = 3'd3;
    localparam RELEASE = 3'd4;
    localparam EX_IDLE = 2'd0;
    localparam EX_ACTIVE = 2'd1;
    localparam EX_DONE = 2'd2;
    localparam EX_RELEASE = 2'd3;
    localparam NST = (SYNC_STAGES < 2) ? 2 : SYNC_STAGES;

    reg [2:0] state;
    reg holdoff;
    reg peer_started_q;
    reg req_q;
    reg [1:0] data_q;
    (* ASYNC_REG = "TRUE" *) reg [NST-1:0] ack_sync;
    (* ASYNC_REG = "TRUE" *) reg [NST-1:0] peer_req_sync;
    reg peer_req_q;
    reg [1:0] peer_state;
    reg peer_ack_q;

    wire [1:0] want = (state == IDLE) ? EX_IDLE :
                      (state == WAIT_PEER) ? EX_DONE :
                      (state == RELEASE) ? EX_RELEASE : EX_ACTIVE;
    // Do not collapse active and done into one launch, and do not
    // report idle while the peer has not yet been shown done.
    wire [1:0] launch =
        ((data_q == EX_IDLE) && (want == EX_DONE)) ? EX_ACTIVE :
        ((data_q == EX_ACTIVE) && ((want == EX_IDLE) || (want == EX_RELEASE))) ? EX_DONE :
        ((data_q == EX_DONE) && (want == EX_IDLE)) ? EX_RELEASE : want;
    wire send_ready = (req_q == ack_sync[NST-1]);
    wire send = send_ready && (launch != data_q);
    wire peer_edge = (peer_req_sync[NST-1] != peer_req_q);
    wire peer_started = (peer_state != EX_IDLE);
    wire peer_done = (peer_state == EX_DONE) || (peer_state == EX_RELEASE);
    wire peer_released = (peer_state == EX_RELEASE);
    wire start = (clear_i || (peer_started && !peer_started_q)) && !holdoff;

    assign isolate_o = (state != IDLE);
    assign clear_o = (state == CLEAR) || (state == WAIT_PEER);
    assign async_req_o = req_q;
    assign async_data_o = data_q;
    assign async_peer_ack_o = peer_ack_q;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            state <= IDLE;
            holdoff <= 1'b0;
            peer_started_q <= 1'b0;
            req_q <= 1'b0;
            data_q <= EX_IDLE;
            ack_sync <= {NST{1'b0}};
            peer_req_sync <= {NST{1'b0}};
            peer_req_q <= 1'b0;
            peer_state <= EX_IDLE;
            peer_ack_q <= 1'b0;
        end else begin
            ack_sync <= {ack_sync[NST-2:0], async_ack_i};
            peer_req_sync <= {peer_req_sync[NST-2:0], async_peer_req_i};
            peer_req_q <= peer_req_sync[NST-1];
            peer_started_q <= peer_started;
            if (peer_edge) begin
                peer_state <= async_peer_data_i;
                peer_ack_q <= ~peer_ack_q;
            end
            if (send) begin
                req_q <= ~req_q;
                data_q <= launch;
            end
            if (peer_state == EX_IDLE)
                holdoff <= 1'b0;
            case (state)
                IDLE: if (start) state <= ISOLATE;
                ISOLATE: if (isolate_ack_i && peer_started) state <= CLEAR;
                CLEAR: if (clear_ack_i) state <= WAIT_PEER;
                WAIT_PEER: if (peer_done) state <= RELEASE;
                RELEASE: if (peer_released && data_q == EX_RELEASE && send_ready) begin
                    state <= IDLE;
                    holdoff <= 1'b1;
                end
                default: state <= IDLE;
            endcase
        end
    end

endmodule
