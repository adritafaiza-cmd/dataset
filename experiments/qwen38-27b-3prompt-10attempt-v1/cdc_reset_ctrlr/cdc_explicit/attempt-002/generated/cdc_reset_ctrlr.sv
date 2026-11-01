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

    // Internal state registers
    reg a_isolate_r;
    reg a_clear_r;
    reg b_isolate_r;
    reg b_clear_r;

    // Synchronizer registers for A domain signals going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_sync;
    reg [SYNC_STAGES-1:0] a_clear_sync;

    // Synchronizer registers for B domain signals going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_sync;
    reg [SYNC_STAGES-1:0] b_clear_sync;

    // Synchronizer registers for A domain acks going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_ack_sync;
    reg [SYNC_STAGES-1:0] a_clear_ack_sync;

    // Synchronizer registers for B domain acks going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_ack_sync;
    reg [SYNC_STAGES-1:0] b_clear_ack_sync;

    // Synchronizer registers for B domain clear request going to A domain
    reg [SYNC_STAGES-1:0] b_clear_req_sync;

    // Synchronizer registers for A domain clear request going to B domain
    reg [SYNC_STAGES-1:0] a_clear_req_sync;

    // Synchronizer registers for A domain isolate request going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_req_sync;

    // Synchronizer registers for B domain isolate request going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_req_sync;

    // Synchronizer registers for A domain clear done going to B domain
    reg [SYNC_STAGES-1:0] a_clear_done_sync;

    // Synchronizer registers for B domain clear done going to A domain
    reg [SYNC_STAGES-1:0] b_clear_done_sync;

    // Synchronizer registers for A domain isolate done going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_done_sync;

    // Synchronizer registers for B domain isolate done going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_done_sync;

    // Synchronizer registers for A domain clear release going to B domain
    reg [SYNC_STAGES-1:0] a_clear_release_sync;

    // Synchronizer registers for B domain clear release going to A domain
    reg [SYNC_STAGES-1:0] b_clear_release_sync;

    // Synchronizer registers for A domain isolate release going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_release_sync;

    // Synchronizer registers for B domain isolate release going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_release_sync;

    // Synchronizer registers for A domain clear ack going to B domain
    reg [SYNC_STAGES-1:0] a_clear_ack_sync;

    // Synchronizer registers for B domain clear ack going to A domain
    reg [SYNC_STAGES-1:0] b_clear_ack_sync;

    // Synchronizer registers for A domain isolate ack going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_ack_sync;

    // Synchronizer registers for B domain isolate ack going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_ack_sync;

    // Synchronizer registers for A domain clear request going to B domain
    reg [SYNC_STAGES-1:0] a_clear_req_sync;

    // Synchronizer registers for B domain clear request going to A domain
    reg [SYNC_STAGES-1:0] b_clear_req_sync;

    // Synchronizer registers for A domain isolate request going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_req_sync;

    // Synchronizer registers for B domain isolate request going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_req_sync;

    // Synchronizer registers for A domain clear done going to B domain
    reg [SYNC_STAGES-1:0] a_clear_done_sync;

    // Synchronizer registers for B domain clear done going to A domain
    reg [SYNC_STAGES-1:0] b_clear_done_sync;

    // Synchronizer registers for A domain isolate done going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_done_sync;

    // Synchronizer registers for B domain isolate done going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_done_sync;

    // Synchronizer registers for A domain clear release going to B domain
    reg [SYNC_STAGES-1:0] a_clear_release_sync;

    // Synchronizer registers for B domain clear release going to A domain
    reg [SYNC_STAGES-1:0] b_clear_release_sync;

    // Synchronizer registers for A domain isolate release going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_release_sync;

    // Synchronizer registers for B domain isolate release going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_release_sync;

    // Synchronizer registers for A domain clear ack going to B domain
    reg [SYNC_STAGES-1:0] a_clear_ack_sync;

    // Synchronizer registers for B domain clear ack going to A domain
    reg [SYNC_STAGES-1:0] b_clear_ack_sync;

    // Synchronizer registers for A domain isolate ack going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_ack_sync;

    // Synchronizer registers for B domain isolate ack going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_ack_sync;

    // Synchronizer registers for A domain clear request going to B domain
    reg [SYNC_STAGES-1:0] a_clear_req_sync;

    // Synchronizer registers for B domain clear request going to A domain
    reg [SYNC_STAGES-1:0] b_clear_req_sync;

    // Synchronizer registers for A domain isolate request going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_req_sync;

    // Synchronizer registers for B domain isolate request going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_req_sync;

    // Synchronizer registers for A domain clear done going to B domain
    reg [SYNC_STAGES-1:0] a_clear_done_sync;

    // Synchronizer registers for B domain clear done going to A domain
    reg [SYNC_STAGES-1:0] b_clear_done_sync;

    // Synchronizer registers for A domain isolate done going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_done_sync;

    // Synchronizer registers for B domain isolate done going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_done_sync;

    // Synchronizer registers for A domain clear release going to B domain
    reg [SYNC_STAGES-1:0] a_clear_release_sync;

    // Synchronizer registers for B domain clear release going to A domain
    reg [SYNC_STAGES-1:0] b_clear_release_sync;

    // Synchronizer registers for A domain isolate release going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_release_sync;

    // Synchronizer registers for B domain isolate release going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_release_sync;

    // Synchronizer registers for A domain clear ack going to B domain
    reg [SYNC_STAGES-1:0] a_clear_ack_sync;

    // Synchronizer registers for B domain clear ack going to A domain
    reg [SYNC_STAGES-1:0] b_clear_ack_sync;

    // Synchronizer registers for A domain isolate ack going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_ack_sync;

    // Synchronizer registers for B domain isolate ack going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_ack_sync;

    // Synchronizer registers for A domain clear request going to B domain
    reg [SYNC_STAGES-1:0] a_clear_req_sync;

    // Synchronizer registers for B domain clear request going to A domain
    reg [SYNC_STAGES-1:0] b_clear_req_sync;

    // Synchronizer registers for A domain isolate request going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_req_sync;

    // Synchronizer registers for B domain isolate request going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_req_sync;

    // Synchronizer registers for A domain clear done going to B domain
    reg [SYNC_STAGES-1:0] a_clear_done_sync;

    // Synchronizer registers for B domain clear done going to A domain
    reg [SYNC_STAGES-1:0] b_clear_done_sync;

    // Synchronizer registers for A domain isolate done going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_done_sync;

    // Synchronizer registers for B domain isolate done going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_done_sync;

    // Synchronizer registers for A domain clear release going to B domain
    reg [SYNC_STAGES-1:0] a_clear_release_sync;

    // Synchronizer registers for B domain clear release going to A domain
    reg [SYNC_STAGES-1:0] b_clear_release_sync;

    // Synchronizer registers for A domain isolate release going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_release_sync;

    // Synchronizer registers for B domain isolate release going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_release_sync;

    // Synchronizer registers for A domain clear ack going to B domain
    reg [SYNC_STAGES-1:0] a_clear_ack_sync;

    // Synchronizer registers for B domain clear ack going to A domain
    reg [SYNC_STAGES-1:0] b_clear_ack_sync;

    // Synchronizer registers for A domain isolate ack going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_ack_sync;

    // Synchronizer registers for B domain isolate ack going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_ack_sync;

    // Synchronizer registers for A domain clear request going to B domain
    reg [SYNC_STAGES-1:0] a_clear_req_sync;

    // Synchronizer registers for B domain clear request going to A domain
    reg [SYNC_STAGES-1:0] b_clear_req_sync;

    // Synchronizer registers for A domain isolate request going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_req_sync;

    // Synchronizer registers for B domain isolate request going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_req_sync;

    // Synchronizer registers for A domain clear done going to B domain
    reg [SYNC_STAGES-1:0] a_clear_done_sync;

    // Synchronizer registers for B domain clear done going to A domain
    reg [SYNC_STAGES-1:0] b_clear_done_sync;

    // Synchronizer registers for A domain isolate done going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_done_sync;

    // Synchronizer registers for B domain isolate done going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_done_sync;

    // Synchronizer registers for A domain clear release going to B domain
    reg [SYNC_STAGES-1:0] a_clear_release_sync;

    // Synchronizer registers for B domain clear release going to A domain
    reg [SYNC_STAGES-1:0] b_clear_release_sync;

    // Synchronizer registers for A domain isolate release going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_release_sync;

    // Synchronizer registers for B domain isolate release going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_release_sync;

    // Synchronizer registers for A domain clear ack going to B domain
    reg [SYNC_STAGES-1:0] a_clear_ack_sync;

    // Synchronizer registers for B domain clear ack going to A domain
    reg [SYNC_STAGES-1:0] b_clear_ack_sync;

    // Synchronizer registers for A domain isolate ack going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_ack_sync;

    // Synchronizer registers for B domain isolate ack going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_ack_sync;

    // Synchronizer registers for A domain clear request going to B domain
    reg [SYNC_STAGES-1:0] a_clear_req_sync;

    // Synchronizer registers for B domain clear request going to A domain
    reg [SYNC_STAGES-1:0] b_clear_req_sync;

    // Synchronizer registers for A domain isolate request going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_req_sync;

    // Synchronizer registers for B domain isolate request going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_req_sync;

    // Synchronizer registers for A domain clear done going to B domain
    reg [SYNC_STAGES-1:0] a_clear_done_sync;

    // Synchronizer registers for B domain clear done going to A domain
    reg [SYNC_STAGES-1:0] b_clear_done_sync;

    // Synchronizer registers for A domain isolate done going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_done_sync;

    // Synchronizer registers for B domain isolate done going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_done_sync;

    // Synchronizer registers for A domain clear release going to B domain
    reg [SYNC_STAGES-1:0] a_clear_release_sync;

    // Synchronizer registers for B domain clear release going to A domain
    reg [SYNC_STAGES-1:0] b_clear_release_sync;

    // Synchronizer registers for A domain isolate release going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_release_sync;

    // Synchronizer registers for B domain isolate release going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_release_sync;

    // Synchronizer registers for A domain clear ack going to B domain
    reg [SYNC_STAGES-1:0] a_clear_ack_sync;

    // Synchronizer registers for B domain clear ack going to A domain
    reg [SYNC_STAGES-1:0] b_clear_ack_sync;

    // Synchronizer registers for A domain isolate ack going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_ack_sync;

    // Synchronizer registers for B domain isolate ack going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_ack_sync;

    // Synchronizer registers for A domain clear request going to B domain
    reg [SYNC_STAGES-1:0] a_clear_req_sync;

    // Synchronizer registers for B domain clear request going to A domain
    reg [SYNC_STAGES-1:0] b_clear_req_sync;

    // Synchronizer registers for A domain isolate request going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_req_sync;

    // Synchronizer registers for B domain isolate request going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_req_sync;

    // Synchronizer registers for A domain clear done going to B domain
    reg [SYNC_STAGES-1:0] a_clear_done_sync;

    // Synchronizer registers for B domain clear done going to A domain
    reg [SYNC_STAGES-1:0] b_clear_done_sync;

    // Synchronizer registers for A domain isolate done going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_done_sync;

    // Synchronizer registers for B domain isolate done going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_done_sync;

    // Synchronizer registers for A domain clear release going to B domain
    reg [SYNC_STAGES-1:0] a_clear_release_sync;

    // Synchronizer registers for B domain clear release going to A domain
    reg [SYNC_STAGES-1:0] b_clear_release_sync;

    // Synchronizer registers for A domain isolate release going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_release_sync;

    // Synchronizer registers for B domain isolate release going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_release_sync;

    // Synchronizer registers for A domain clear ack going to B domain
    reg [SYNC_STAGES-1:0] a_clear_ack_sync;

    // Synchronizer registers for B domain clear ack going to A domain
    reg [SYNC_STAGES-1:0] b_clear_ack_sync;

    // Synchronizer registers for A domain isolate ack going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_ack_sync;

    // Synchronizer registers for B domain isolate ack going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_ack_sync;

    // Synchronizer registers for A domain clear request going to B domain
    reg [SYNC_STAGES-1:0] a_clear_req_sync;

    // Synchronizer registers for B domain clear request going to A domain
    reg [SYNC_STAGES-1:0] b_clear_req_sync;

    // Synchronizer registers for A domain isolate request going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_req_sync;

    // Synchronizer registers for B domain isolate request going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_req_sync;

    // Synchronizer registers for A domain clear done going to B domain
    reg [SYNC_STAGES-1:0] a_clear_done_sync;

    // Synchronizer registers for B domain clear done going to A domain
    reg [SYNC_STAGES-1:0] b_clear_done_sync;

    // Synchronizer registers for A domain isolate done going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_done_sync;

    // Synchronizer registers for B domain isolate done going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_done_sync;

    // Synchronizer registers for A domain clear release going to B domain
    reg [SYNC_STAGES-1:0] a_clear_release_sync;

    // Synchronizer registers for B domain clear release going to A domain
    reg [SYNC_STAGES-1:0] b_clear_release_sync;

    // Synchronizer registers for A domain isolate release going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_release_sync;

    // Synchronizer registers for B domain isolate release going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_release_sync;

    // Synchronizer registers for A domain clear ack going to B domain
    reg [SYNC_STAGES-1:0] a_clear_ack_sync;

    // Synchronizer registers for B domain clear ack going to A domain
    reg [SYNC_STAGES-1:0] b_clear_ack_sync;

    // Synchronizer registers for A domain isolate ack going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_ack_sync;

    // Synchronizer registers for B domain isolate ack going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_ack_sync;

    // Synchronizer registers for A domain clear request going to B domain
    reg [SYNC_STAGES-1:0] a_clear_req_sync;

    // Synchronizer registers for B domain clear request going to A domain
    reg [SYNC_STAGES-1:0] b_clear_req_sync;

    // Synchronizer registers for A domain isolate request going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_req_sync;

    // Synchronizer registers for B domain isolate request going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_req_sync;

    // Synchronizer registers for A domain clear done going to B domain
    reg [SYNC_STAGES-1:0] a_clear_done_sync;

    // Synchronizer registers for B domain clear done going to A domain
    reg [SYNC_STAGES-1:0] b_clear_done_sync;

    // Synchronizer registers for A domain isolate done going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_done_sync;

    // Synchronizer registers for B domain isolate done going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_done_sync;

    // Synchronizer registers for A domain clear release going to B domain
    reg [SYNC_STAGES-1:0] a_clear_release_sync;

    // Synchronizer registers for B domain clear release going to A domain
    reg [SYNC_STAGES-1:0] b_clear_release_sync;

    // Synchronizer registers for A domain isolate release going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_release_sync;

    // Synchronizer registers for B domain isolate release going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_release_sync;

    // Synchronizer registers for A domain clear ack going to B domain
    reg [SYNC_STAGES-1:0] a_clear_ack_sync;

    // Synchronizer registers for B domain clear ack going to A domain
    reg [SYNC_STAGES-1:0] b_clear_ack_sync;

    // Synchronizer registers for A domain isolate ack going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_ack_sync;

    // Synchronizer registers for B domain isolate ack going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_ack_sync;

    // Synchronizer registers for A domain clear request going to B domain
    reg [SYNC_STAGES-1:0] a_clear_req_sync;

    // Synchronizer registers for B domain clear request going to A domain
    reg [SYNC_STAGES-1:0] b_clear_req_sync;

    // Synchronizer registers for A domain isolate request going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_req_sync;

    // Synchronizer registers for B domain isolate request going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_req_sync;

    // Synchronizer registers for A domain clear done going to B domain
    reg [SYNC_STAGES-1:0] a_clear_done_sync;

    // Synchronizer registers for B domain clear done going to A domain
    reg [SYNC_STAGES-1:0] b_clear_done_sync;

    // Synchronizer registers for A domain isolate done going to B domain
    reg [SYNC_STAGES-1:0] a_isolate_done_sync;

    // Synchronizer registers for B domain isolate done going to A domain
    reg [SYNC_STAGES-1:0] b_isolate_done_sync;

    // Synchronizer registers for A domain clear release going to B domain
    reg [SYNC_STAGES-1:0] a_clear_release_sync;

    // Synchronizer registers for B domain