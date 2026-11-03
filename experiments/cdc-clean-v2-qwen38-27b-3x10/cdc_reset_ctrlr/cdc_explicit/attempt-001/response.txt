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

    // State encoding
    localparam S_IDLE      = 3'd0;
    localparam S_ISOLATE   = 3'd1;
    localparam S_CLEAR     = 3'd2;
    localparam S_RELEASE   = 3'd3;
    localparam S_DONE      = 3'd4;

    // Internal state registers
    reg [2:0] a_state;
    reg [2:0] b_state;

    // Synchronizer registers for A->B status
    reg [SYNC_STAGES-1:0] a_to_b_sync;
    reg [2:0] a_to_b_status;

    // Synchronizer registers for B->A status
    reg [SYNC_STAGES-1:0] b_to_a_sync;
    reg [2:0] b_to_a_status;

    // Synchronizer registers for A->B clear request
    reg [SYNC_STAGES-1:0] a_to_b_clear_sync;
    reg a_to_b_clear;

    // Synchronizer registers for B->A clear request
    reg [SYNC_STAGES-1:0] b_to_a_clear_sync;
    reg b_to_a_clear;

    // Synchronizer registers for A->B isolate ack
    reg [SYNC_STAGES-1:0] a_to_b_iso_ack_sync;
    reg a_to_b_iso_ack;

    // Synchronizer registers for B->A isolate ack
    reg [SYNC_STAGES-1:0] b_to_a_iso_ack_sync;
    reg b_to_a_iso_ack;

    // Synchronizer registers for A->B clear ack
    reg [SYNC_STAGES-1:0] a_to_b_clr_ack_sync;
    reg a_to_b_clr_ack;

    // Synchronizer registers for B->A clear ack
    reg [SYNC_STAGES-1:0] b_to_a_clr_ack_sync;
    reg b_to_a_clr_ack;

    // Synchronizer registers for A->B release status
    reg [SYNC_STAGES-1:0] a_to_b_rel_sync;
    reg a_to_b_rel;

    // Synchronizer registers for B->A release status
    reg [SYNC_STAGES-1:0] b_to_a_rel_sync;
    reg b_to_a_rel;

    // Synchronizer registers for A->B done status
    reg [SYNC_STAGES-1:0] a_to_b_done_sync;
    reg a_to_b_done;

    // Synchronizer registers for B->A done status
    reg [SYNC_STAGES-1:0] b_to_a_done_sync;
    reg b_to_a_done;

    // Synchronizer registers for A->B idle status
    reg [SYNC_STAGES-1:0] a_to_b_idle_sync;
    reg a_to_b_idle;

    // Synchronizer registers for B->A idle status
    reg [SYNC_STAGES-1:0] b_to_a_idle_sync;
    reg b_to_a_idle;

    // Synchronizer for A->B isolate request
    reg [SYNC_STAGES-1:0] a_to_b_iso_sync;
    reg a_to_b_iso;

    // Synchronizer for B->A isolate request
    reg [SYNC_STAGES-1:0] b_to_a_iso_sync;
    reg b_to_a_iso;

    // Synchronizer for A->B clear request (separate from status)
    reg [SYNC_STAGES-1:0] a_to_b_clr_req_sync;
    reg a_to_b_clr_req;

    // Synchronizer for B->A clear request
    reg [SYNC_STAGES-1:0] b_to_a_clr_req_sync;
    reg b_to_a_clr_req;

    // Synchronizer for A->B release request
    reg [SYNC_STAGES-1:0] a_to_b_rel_req_sync;
    reg a_to_b_rel_req;

    // Synchronizer for B->A release request
    reg [SYNC_STAGES-1:0] b_to_a_rel_req_sync;
    reg b_to_a_rel_req;

    // Synchronizer for A->B done request
    reg [SYNC_STAGES-1:0] a_to_b_done_req_sync;
    reg a_to_b_done_req;

    // Synchronizer for B->A done request
    reg [SYNC_STAGES-1:0] b_to_a_done_req_sync;
    reg b_to_a_done_req;

    // Synchronizer for A->B idle request
    reg [SYNC_STAGES-1:0] a_to_b_idle_req_sync;
    reg a_to_b_idle_req;

    // Synchronizer for B->A idle request
    reg [SYNC_STAGES-1:0] b_to_a_idle_req_sync;
    reg b_to_a_idle_req;

    // Synchronizer for A->B isolate ack
    reg [SYNC_STAGES-1:0] a_to_b_iso_ack_req_sync;
    reg a_to_b_iso_ack_req;

    // Synchronizer for B->A isolate ack
    reg [SYNC_STAGES-1:0] b_to_a_iso_ack_req_sync;
    reg b_to_a_iso_ack_req;

    // Synchronizer for A->B clear ack
    reg [SYNC_STAGES-1:0] a_to_b_clr_ack_req_sync;
    reg a_to_b_clr_ack_req;

    // Synchronizer for B->A clear ack
    reg [SYNC_STAGES-1:0] b_to_a_clr_ack_req_sync;
    reg b_to_a_clr_ack_req;

    // Synchronizer for A->B release ack
    reg [SYNC_STAGES-1:0] a_to_b_rel_ack_sync;
    reg a_to_b_rel_ack;

    // Synchronizer for B->A release ack
    reg [SYNC_STAGES-1:0] b_to_a_rel_ack_sync;
    reg b_to_a_rel_ack;

    // Synchronizer for A->B done ack
    reg [SYNC_STAGES-1:0] a_to_b_done_ack_sync;
    reg a_to_b_done_ack;

    // Synchronizer for B->A done ack
    reg [SYNC_STAGES-1:0] b_to_a_done_ack_sync;
    reg b_to_a_done_ack;

    // Synchronizer for A->B idle ack
    reg [SYNC_STAGES-1:0] a_to_b_idle_ack_sync;
    reg a_to_b_idle_ack;

    // Synchronizer for B->A idle ack
    reg [SYNC_STAGES-1:0] b_to_a_idle_ack_sync;
    reg b_to_a_idle_ack;

    // Synchronizer for A->B isolate req
    reg [SYNC_STAGES-1:0] a_to_b_iso_req_sync;
    reg a_to_b_iso_req;

    // Synchronizer for B->A isolate req
    reg [SYNC_STAGES-1:0] b_to_a_iso_req_sync;
    reg b_to_a_iso_req;

    // Synchronizer for A->B clear req
    reg [SYNC_STAGES-1:0] a_to_b_clr_req2_sync;
    reg a_to_b_clr_req2;

    // Synchronizer for B->A clear req
    reg [SYNC_STAGES-1:0] b_to_a_clr_req2_sync;
    reg b_to_a_clr_req2;

    // Synchronizer for A->B release req
    reg [SYNC_STAGES-1:0] a_to_b_rel_req2_sync;
    reg a_to_b_rel_req2;

    // Synchronizer for B->A release req
    reg [SYNC_STAGES-1:0] b_to_a_rel_req2_sync;
    reg b_to_a_rel_req2;

    // Synchronizer for A->B done req
    reg [SYNC_STAGES-1:0] a_to_b_done_req2_sync;
    reg a_to_b_done_req2;

    // Synchronizer for B->A done req
    reg [SYNC_STAGES-1:0] b_to_a_done_req2_sync;
    reg b_to_a_done_req2;

    // Synchronizer for A->B idle req
    reg [SYNC_STAGES-1:0] a_to_b_idle_req2_sync;
    reg a_to_b_idle_req2;

    // Synchronizer for B->A idle req
    reg [SYNC_STAGES-1:0] b_to_a_idle_req2_sync;
    reg b_to_a_idle_req2;

    // Synchronizer for A->B isolate ack
    reg [SYNC_STAGES-1:0] a_to_b_iso_ack2_sync;
    reg a_to_b_iso_ack2;

    // Synchronizer for B->A isolate ack
    reg [SYNC_STAGES-1:0] b_to_a_iso_ack2_sync;
    reg b_to_a_iso_ack2;

    // Synchronizer for A->B clear ack
    reg [SYNC_STAGES-1:0] a_to_b_clr_ack2_sync;
    reg a_to_b_clr_ack2;

    // Synchronizer for B->A clear ack
    reg [SYNC_STAGES-1:0] b_to_a_clr_ack2_sync;
    reg b_to_a_clr_ack2;

    // Synchronizer for A->B release ack
    reg [SYNC_STAGES-1:0] a_to_b_rel_ack2_sync;
    reg a_to_b_rel_ack2;

    // Synchronizer for B->A release ack
    reg [SYNC_STAGES-1:0] b_to_a_rel_ack2_sync;
    reg b_to_a_rel_ack2;

    // Synchronizer for A->B done ack
    reg [SYNC_STAGES-1:0] a_to_b_done_ack2_sync;
    reg a_to_b_done_ack2;

    // Synchronizer for B->A done ack
    reg [SYNC_STAGES-1:0] b_to_a_done_ack2_sync;
    reg b_to_a_done_ack2;

    // Synchronizer for A->B idle ack
    reg [SYNC_STAGES-1:0] a_to_b_idle_ack2_sync;
    reg a_to_b_idle_ack2;

    // Synchronizer for B->A idle ack
    reg [SYNC_STAGES-1:0] b_to_a_idle_ack2_sync;
    reg b_to_a_idle_ack2;

    // Synchronizer for A->B isolate req
    reg [SYNC_STAGES-1:0] a_to_b_iso_req2_sync;
    reg a_to_b_iso_req2;

    // Synchronizer for B->A isolate req
    reg [SYNC_STAGES-1:0] b_to_a_iso_req2_sync;
    reg b_to_a_iso_req2;

    // Synchronizer for A->B clear req
    reg [SYNC_STAGES-1:0] a_to_b_clr_req3_sync;
    reg a_to_b_clr_req3;

    // Synchronizer for B->A clear req
    reg [SYNC_STAGES-1:0] b_to_a_clr_req3_sync;
    reg b_to_a_clr_req3;

    // Synchronizer for A->B release req
    reg [SYNC_STAGES-1:0] a_to_b_rel_req3_sync;
    reg a_to_b_rel_req3;

    // Synchronizer for B->A release req
    reg [SYNC_STAGES-1:0] b_to_a_rel_req3_sync;
    reg b_to_a_rel_req3;

    // Synchronizer for A->B done req
    reg [SYNC_STAGES-1:0] a_to_b_done_req3_sync;
    reg a_to_b_done_req3;

    // Synchronizer for B->A done req
    reg [SYNC_STAGES-1:0] b_to_a_done_req3_sync;
    reg b_to_a_done_req3;

    // Synchronizer for A->B idle req
    reg [SYNC_STAGES-1:0] a_to_b_idle_req3_sync;
    reg a_to_b_idle_req3;

    // Synchronizer for B->A idle req
    reg [SYNC_STAGES-1:0] b_to_a_idle_req3_sync;
    reg b_to_a_idle_req3;

    // Synchronizer for A->B isolate ack
    reg [SYNC_STAGES-1:0] a_to_b_iso_ack3_sync;
    reg a_to_b_iso_ack3;

    // Synchronizer for B->A isolate ack
    reg [SYNC_STAGES-1:0] b_to_a_iso_ack3_sync;
    reg b_to_a_iso_ack3;

    // Synchronizer for A->B clear ack
    reg [SYNC_STAGES-1:0] a_to_b_clr_ack3_sync;
    reg a_to_b_clr_ack3;

    // Synchronizer for B->A clear ack
    reg [SYNC_STAGES-1:0] b_to_a_clr_ack3_sync;
    reg b_to_a_clr_ack3;

    // Synchronizer for A->B release ack
    reg [SYNC_STAGES-1:0] a_to_b_rel_ack3_sync;
    reg a_to_b_rel_ack3;

    // Synchronizer for B->A release ack
    reg [SYNC_STAGES-1:0] b_to_a_rel_ack3_sync;
    reg b_to_a_rel_ack3;

    // Synchronizer for A->B done ack
    reg [SYNC_STAGES-1:0] a_to_b_done_ack3_sync;
    reg a_to_b_done_ack3;

    // Synchronizer for B->A done ack
    reg [SYNC_STAGES-1:0] b_to_a_done_ack3_sync;
    reg b_to_a_done_ack3;

    // Synchronizer for A->B idle ack
    reg [SYNC_STAGES-1:0] a_to_b_idle_ack3_sync;
    reg a_to_b_idle_ack3;

    // Synchronizer for B->A idle ack
    reg [SYNC_STAGES-1:0] b_to_a_idle_ack3_sync;
    reg b_to_a_idle_ack3;

    // Synchronizer for A->B isolate req
    reg [SYNC_STAGES-1:0] a_to_b_iso_req3_sync;
    reg a_to_b_iso_req3;

    // Synchronizer for B->A isolate req
    reg [SYNC_STAGES-1:0] b_to_a_iso_req3_sync;
    reg b_to_a_iso_req3;

    // Synchronizer for A->B clear req
    reg [SYNC_STAGES-1:0] a_to_b_clr_req4_sync;
    reg a_to_b_clr_req4;

    // Synchronizer for B->A clear req
    reg [SYNC_STAGES-1:0] b_to_a_clr_req4_sync;
    reg b_to_a_clr_req4;

    // Synchronizer for A->B release req
    reg [SYNC_STAGES-1:0] a_to_b_rel_req4_sync;
    reg a_to_b_rel_req4;

    // Synchronizer for B->A release req
    reg [SYNC_STAGES-1:0] b_to_a_rel_req4_sync;
    reg b_to_a_rel_req4;

    // Synchronizer for A->B done req
    reg [SYNC_STAGES-1:0] a_to_b_done_req4_sync;
    reg a_to_b_done_req4;

    // Synchronizer for B->A done req
    reg [SYNC_STAGES-1:0] b_to_a_done_req4_sync;
    reg b_to_a_done_req4;

    // Synchronizer for A->B idle req
    reg [SYNC_STAGES-1:0] a_to_b_idle_req4_sync;
    reg a_to_b_idle_req4;

    // Synchronizer for B->A idle req
    reg [SYNC_STAGES-1:0] b_to_a_idle_req4_sync;
    reg b_to_a_idle_req4;

    // Synchronizer for A->B isolate ack
    reg [SYNC_STAGES-1:0] a_to_b_iso_ack4_sync;
    reg a_to_b_iso_ack4;

    // Synchronizer for B->A isolate ack
    reg [SYNC_STAGES-1:0] b_to_a_iso_ack4_sync;
    reg b_to_a_iso_ack4;

    // Synchronizer for A->B clear ack
    reg [SYNC_STAGES-1:0] a_to_b_clr_ack4_sync;
    reg a_to_b_clr_ack4;

    // Synchronizer for B->A clear ack
    reg [SYNC_STAGES-1:0] b_to_a_clr_ack4_sync;
    reg b_to_a_clr_ack4;

    // Synchronizer for A->B release ack
    reg [SYNC_STAGES-1:0] a_to_b_rel_ack4_sync;
    reg a_to_b_rel_ack4;

    // Synchronizer for B->A release ack
    reg [SYNC_STAGES-1:0] b_to_a_rel_ack4_sync;
    reg b_to_a_rel_ack4;

    // Synchronizer for A->B done ack
    reg [SYNC_STAGES-1:0] a_to_b_done_ack4_sync;
    reg a_to_b_done_ack4;

    // Synchronizer for B->A done ack
    reg [SYNC_STAGES-1:0] b_to_a_done_ack4_sync;
    reg b_to_a_done_ack4;

    // Synchronizer for A->B idle ack
    reg [SYNC_STAGES-1:0] a_to_b_idle_ack4_sync;
    reg a_to_b_idle_ack4;

    // Synchronizer for B->A idle ack
    reg [SYNC_STAGES-1:0] b_to_a_idle_ack4_sync;
    reg b_to_a_idle_ack4;

    // Synchronizer for A->B isolate req
    reg [SYNC_STAGES-1:0] a_to_b_iso_req4_sync;
    reg a_to_b_iso_req4;

    // Synchronizer for B->A isolate req
    reg [SYNC_STAGES-1:0] b_to_a_iso_req4_sync;
    reg b_to_a_iso_req4;

    // Synchronizer for A->B clear req
    reg [SYNC_STAGES-1:0] a_to_b_clr_req5_sync;
    reg a_to_b_clr_req5;

    // Synchronizer for B->A clear req
    reg [SYNC_STAGES-1:0] b_to_a_clr_req5_sync;
    reg b_to_a_clr_req5;

    // Synchronizer for A->B release req
    reg [SYNC_STAGES-1:0] a_to_b_rel_req5_sync;
    reg a_to_b_rel_req5;

    // Synchronizer for B->A release req
    reg [SYNC_STAGES-1:0] b_to_a_rel_req5_sync;
    reg b_to_a_rel_req5;

    // Synchronizer for A->B done req
    reg [SYNC_STAGES-1:0] a_to_b_done_req5_sync;
    reg a_to_b_done_req5;

    // Synchronizer for B->A done req
    reg [SYNC_STAGES-1:0] b_to_a_done_req5_sync;
    reg b_to_a_done_req5;

    // Synchronizer for A->B idle req
    reg [SYNC_STAGES-1:0] a_to_b_idle_req5_sync;
    reg a_to_b_idle_req5;

    // Synchronizer for B->A idle req
    reg [SYNC_STAGES-1:0] b_to_a_idle_req5_sync;
    reg b_to_a_idle_req5;

    // Synchronizer for A->B isolate ack
    reg [SYNC_STAGES-1:0] a_to_b_iso_ack5_sync;
    reg a_to_b_iso_ack5;

    // Synchronizer for B->A isolate ack
    reg [SYNC_STAGES-1:0] b_to_a_iso_ack5_sync;
    reg b_to_a_iso_ack5;

    // Synchronizer for A->B clear ack
    reg [SYNC_STAGES-1:0] a_to_b_clr_ack5_sync;
    reg a_to_b_clr_ack5;

    // Synchronizer for B->A clear ack
    reg [SYNC_STAGES-1:0] b_to_a_clr_ack5_sync;
    reg b_to_a_clr_ack5;

    // Synchronizer for A->B release ack
    reg [SYNC_STAGES-1:0] a_to_b_rel_ack5_sync;
    reg a_to_b_rel_ack5;

    // Synchronizer for B->A release ack
    reg [SYNC_STAGES-1:0] b_to_a_rel_ack5_sync;
    reg b_to_a_rel_ack5;

    // Synchronizer for A->B done ack
    reg [SYNC_STAGES-1:0] a_to_b_done_ack5_sync;
    reg a_to_b_done_ack5;

    // Synchronizer for B->A done ack
    reg [SYNC_STAGES-1:0] b_to_a_done_ack5_sync;
    reg b_to_a_done_ack5;

    // Synchronizer for A->B idle ack
    reg [SYNC_STAGES-1:0] a_to_b_idle_ack5_sync;
    reg a_to_b_idle_ack5;

    // Synchronizer for B->A idle ack
    reg [SYNC_STAGES-1:0] b_to_a_idle_ack5_sync;
    reg b_to_a_idle_ack5;

    // Synchronizer for A->B isolate req
    reg [SYNC_STAGES-1:0] a_to_b_iso_req5_sync;
    reg a_to_b_iso_req5;

    // Synchronizer for B->A isolate req
    reg [SYNC_STAGES-1:0] b_to_a_iso_req5_sync;
    reg b_to_a_iso_req5;

    // Synchronizer for A->B clear req
    reg [SYNC_STAGES-1:0] a_to_b_clr_req6_sync;
    reg a_to_b_clr_req6;

    // Synchronizer for B->A clear req
    reg [SYNC_STAGES-1:0] b_to_a_clr_req6_sync;
    reg b_to_a_clr_req6;

    // Synchronizer for A->B release req
    reg [SYNC_STAGES-1:0] a_to_b_rel_req6_sync;
    reg a_to_b_rel_req6;

    // Synchronizer for B->A release req
    reg [SYNC_STAGES-1:0] b_to_a_rel_req6_sync;
    reg b_to_a_rel_req6;

    // Synchronizer for A->B done req
    reg [SYNC_STAGES-1:0] a_to_b_done_req6_sync;
    reg a_to_b_done_req6;

    // Synchronizer for B->A done req
    reg [SYNC_STAGES-1:0] b_to_a_done_req6_sync;
    reg b_to_a_done_req6;

    // Synchronizer for A->B idle req
    reg [SYNC_STAGES-1:0] a_to_b_idle_req6_sync;
    reg a_to_b_idle_req6;

    // Synchronizer for B->A idle req
    reg [SYNC_STAGES-1:0] b_to_a_idle_req6_sync;
    reg b_to_a_idle_req6;

    // Synchronizer for A->B isolate ack
    reg [SYNC_STAGES-1:0] a_to_b_iso_ack6_sync;
    reg a_to_b_iso_ack6;

    // Synchronizer for B->A isolate ack
    reg [SYNC_STAGES-1:0] b_to_a_iso_ack6_sync;
    reg b_to_a_iso_ack6;

    // Synchronizer for A->B clear ack
    reg [SYNC_STAGES-1:0] a_to_b_clr_ack6_sync;
    reg a_to_b_clr_ack6;

    // Synchronizer for B->A clear ack
    reg [SYNC_STAGES-1:0] b_to_a_clr_ack6_sync;
    reg b_to_a_clr_ack6;

    // Synchronizer for A->B release ack
    reg [SYNC_STAGES-1:0] a_to_b_rel_ack6_sync;
    reg a_to_b_rel_ack6;

    // Synchronizer for B->A release ack
    reg [SYNC_STAGES-1:0] b_to_a_rel_ack6_sync;
    reg b_to_a_rel_ack6;

    // Synchronizer for A->B done ack
    reg [SYNC_STAGES-1:0] a_to_b_done_ack6_sync;
    reg a_to_b_done_ack6;

    // Synchronizer for B->A done ack
    reg [SYNC_STAGES-1:0] b_to_a_done_ack6_sync;
    reg b_to_a_done_ack6;

    // Synchronizer for A->B idle ack
    reg [SYNC_STAGES-1:0] a_to_b_idle_ack6_sync;
    reg a_to_b_idle_ack6;

    // Synchronizer for B->A idle ack
    reg [SYNC_STAGES-1:0] b_to_a_idle_ack6_sync;
    reg b_to_a_idle_ack6;

    // Synchronizer for A->B isolate req
    reg [SYNC_STAGES-1:0] a_to_b_iso_req6_sync;
    reg a_to_b_iso_req6;

    // Synchronizer for B->A isolate req
    reg [SYNC_STAGES-1:0] b_to_a_iso_req6_sync;
    reg b_to_a_iso_req6;

    // Synchronizer for A->B clear req
    reg [SYNC_STAGES-1:0] a_to_b_clr_req7_sync;
    reg a_to_b_clr_req7;

    // Synchronizer for B->A clear req
    reg [SYNC_STAGES-1:0] b_to_a_clr_req7_sync;
    reg b_to_a_clr_req7;

    // Synchronizer for A->B release req
    reg [SYNC_STAGES-1:0] a_to_b_rel_req7_sync;
    reg a_to_b_rel_req7;

    // Synchronizer for B->A release req
    reg [SYNC_STAGES-1:0] b_to_a_rel_req7_sync;
    reg b_to_a_rel_req7;

    // Synchronizer for A->B done req
    reg [SYNC_STAGES-1:0] a_to_b_done_req7_sync;
    reg a_to_b_done_req7;

    // Synchronizer for B->A done req
    reg [SYNC_STAGES-1:0] b_to_a_done_req7_sync;
    reg b_to_a_done_req7;

    // Synchronizer for A->B idle req
    reg [SYNC_STAGES-1:0] a_to_b_idle_req7_sync;
    reg a_to_b_idle_req7;

    // Synchronizer for B->A idle req
    reg [SYNC_STAGES-1:0] b_to_a_idle_req7_sync;
    reg b_to_a_idle_req7;

    // Synchronizer for A->B isolate ack
    reg [SYNC_STAGES-1:0] a_to_b_iso_ack7_sync;
    reg a_to_b_iso_ack7;

    // Synchronizer for B->A isolate ack
    reg [SYNC_STAGES-1:0] b_to_a_iso_ack7_sync;
    reg b_to_a_iso_ack7;

    // Synchronizer for A->B clear ack
    reg [SYNC_STAGES-1:0] a_to_b_clr_ack7_sync;
    reg a_to_b_clr_ack7;

    // Synchronizer for B->A clear ack
    reg [SYNC_STAGES-1:0] b_to_a_clr_ack7_sync;
    reg b_to_a_clr_ack7;

    // Synchronizer for A->B release ack
    reg [SYNC_STAGES-1:0] a_to_b_rel_ack7_sync;
    reg a_to_b_rel_ack7;

    // Synchronizer for B->A release ack
    reg [SYNC_STAGES-1:0] b_to_a_rel_ack7_sync;
    reg b_to_a_rel_ack7;

    // Synchronizer for A->B done ack
    reg [SYNC_STAGES-1:0] a_to_b_done_ack7_sync;
    reg a_to_b_done_ack7;

    // Synchronizer for B->A done ack
    reg [SYNC_STAGES-1:0] b_to_a_done_ack7_sync;
    reg b_to_a_done_ack7;

    // Synchronizer for A->B idle ack
    reg [SYNC_STAGES-1:0] a_to_b_idle_ack7_sync;
    reg a_to_b_idle_ack7;

    // Synchronizer for B->A idle ack
    reg [SYNC_STAGES-1:0] b_to_a_idle_ack7_sync;
    reg b_to_a_idle_ack7;

    // Synchronizer for A->B isolate req
    reg [SYNC_STAGES-1:0] a_to_b_iso_req7_sync;
    reg a_to_b_iso_req7;

    // Synchronizer for B->A isolate req
    reg [SYNC_STAGES-1:0] b_to_a_iso_req7_sync;
    reg b_to_a_iso_req7;

    // Synchronizer for A->B clear req
    reg [SYNC_STAGES-1:0] a_to_b_clr_req8_sync;
    reg a_to_b_clr_req8;

    // Synchronizer for B->A clear req
    reg [SYNC_STAGES-1:0] b_to_a_clr_req8_sync;
    reg b_to_a_clr_req8;

    // Synchronizer for A->B release req
    reg [SYNC_STAGES-1:0] a_to_b_rel_req8_sync;
    reg a_to_b_rel_req8;

    // Synchronizer for B->A release req
    reg [SYNC_STAGES-1:0] b_to_a_rel_req8_sync;
    reg b_to_a_rel_req8;

    // Synchronizer for A->B done req
    reg [SYNC_STAGES-1:0] a_to_b_done_req8_sync;
    reg a_to_b_done_req8;

    // Synchronizer for B->A done req
    reg [SYNC_STAGES-1:0] b_to_a_done_req8_sync;
    reg b_to_a_done_req8;

    // Synchronizer for A->B idle req
    reg [SYNC_STAGES-1:0] a_to_b_idle_req8_sync;
    reg a_to_b_idle_req8;

    // Synchronizer for B->A idle req
    reg [SYNC_STAGES-1:0] b_to_a_idle_req8_sync;
    reg b_to_a_idle_req8;

    // Synchronizer for A->B isolate ack
    reg [SYNC_STAGES-1:0] a_to_b_iso_ack8_sync;
    reg a_to_b_iso_ack8;

    // Synchronizer for B->A isolate ack
    reg [SYNC_STAGES-1:0] b_to_a_iso_ack8_sync;
    reg b_to_a_iso_ack8;

    // Synchronizer for A->B clear ack
    reg [SYNC_STAGES-1:0] a_to_b_clr_ack8_sync;
    reg a_to_b_clr_ack8;

    // Synchronizer for B->A clear ack
    reg [SYNC_STAGES-1:0] b_to_a_clr_ack8_sync;
    reg b_to_a_clr_ack8;

    // Synchronizer for A->B release ack
    reg [SYNC_STAGES-1:0] a_to_b_rel_ack8_sync;
    reg a_to_b_rel_ack8;

    // Synchronizer for B->A release ack
    reg [SYNC_STAGES-1:0] b_to_a_rel_ack8_sync;
    reg b_to_a_rel_ack8;

    // Synchronizer for A->B done ack
    reg [SYNC_STAGES-1:0] a_to_b_done_ack8_sync;
    reg a_to_b_done_ack8;

    // Synchronizer for B->A done ack
    reg [SYNC_STAGES-1:0] b_to_a_done_ack8_sync;
    reg b_to_a_done_ack8;

    // Synchronizer for A->B idle ack
    reg [SYNC_STAGES-1:0] a_to_b_idle_ack8_sync;
    reg a_to_b_idle_ack8;

    // Synchronizer for B->A idle ack
    reg [SYNC_STAGES-1:0] b_to_a_idle_ack8_sync;
    reg b_to_a_idle_ack8;

    // Synchronizer for A->B isolate req
    reg [SYNC_STAGES-1:0] a_to_b_iso_req8_sync;
    reg a_to_b_iso_req8;

    // Synchronizer for B->A isolate req
    reg [SYNC_STAGES-1:0] b_to_a_iso_req8_sync;
    reg b_to_a_iso_req8;

    // Synchronizer for A->B clear req
    reg [SYNC_STAGES-1:0] a_to_b_clr_req9_sync;
    reg a_to_b_clr_req9;

    // Synchronizer for B->A clear req
    reg [SYNC_STAGES-1:0] b_to_a_clr_req9_sync;
    reg b_to_a_clr_req9;

    // Synchronizer for A->B release req
    reg [SYNC_STAGES-1:0] a_to_b_rel_req9_sync;
    reg a_to_b_rel_req9;

    // Synchronizer for B->A release req
    reg [SYNC_STAGES-1:0] b_to_a_rel_req9_sync;
    reg b_to_a_rel_req9;

    // Synchronizer for A->B done req
    reg [SYNC_STAGES-1:0] a_to_b_done_req9_sync;
    reg a_to_b_done_req9;

    // Synchronizer for B->A done req
    reg [SYNC_STAGES-1:0] b_to_a_done_req9_sync;
    reg b_to_a_done_req9;

    // Synchronizer for A->B idle req
    reg [SYNC_STAGES-1:0] a_to_b_idle_req9_sync;
    reg a_to_b_idle_req9;

    // Synchronizer for B->A idle req
    reg [SYNC_STAGES-1:0] b_to_a_idle_req9_sync;
    reg b_to_a_idle_req9;

    // Synchronizer for A->B isolate ack
    reg [SYNC_STAGES-1:0] a_to_b_iso_ack9_sync;
    reg a_to_b_iso_ack9;

    // Synchronizer for B->A isolate ack
    reg [SYNC_STAGES-1:0] b_to_a_iso_ack9_sync;
    reg b_to_a_iso_ack9;

    // Synchronizer for A->B clear ack
    reg [SYNC_STAGES-1:0] a_to_b_clr_ack9_sync;
    reg a_to_b_clr_ack9;

    // Synchronizer for B->A clear ack
    reg [SYNC_STAGES-1:0] b_to_a_clr_ack9_sync;
    reg b_to_a_clr_ack9;

    // Synchronizer for A->B release ack
    reg [SYNC_STAGES-1:0] a_to_b_rel_ack9_sync;
    reg a_to_b_rel_ack9;

    // Synchronizer for B->A release ack
    reg [SYNC_STAGES-1:0] b_to_a_rel_ack9_sync;
    reg b_to_a_rel_ack9;

    // Synchronizer for A->B done ack
    reg [SYNC_STAGES-1:0] a_to_b_done_ack9_sync