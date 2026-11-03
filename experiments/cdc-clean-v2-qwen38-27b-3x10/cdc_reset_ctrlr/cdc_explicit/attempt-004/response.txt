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
    reg [2:0] a_state_r;
    reg [2:0] b_state_r;

    // Synchronizer registers for A->B status
    reg [2:0] a_status_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A status
    reg [2:0] b_status_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B clear request
    reg a_clear_req_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A clear request
    reg b_clear_req_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B isolate ack
    reg a_isolate_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A isolate ack
    reg b_isolate_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B clear ack
    reg a_clear_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A clear ack
    reg b_clear_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B release status
    reg a_release_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A release status
    reg b_release_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B done status
    reg a_done_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A done status
    reg b_done_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B idle status
    reg a_idle_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A idle status
    reg b_idle_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B active status
    reg a_active_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A active status
    reg b_active_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B clear status
    reg a_clear_status_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A clear status
    reg b_clear_status_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B isolate status
    reg a_isolate_status_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A isolate status
    reg b_isolate_status_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B release ack
    reg a_release_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A release ack
    reg b_release_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B done ack
    reg a_done_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A done ack
    reg b_done_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B idle ack
    reg a_idle_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A idle ack
    reg b_idle_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B active ack
    reg a_active_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A active ack
    reg b_active_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B clear status ack
    reg a_clear_status_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A clear status ack
    reg b_clear_status_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B isolate status ack
    reg a_isolate_status_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A isolate status ack
    reg b_isolate_status_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B release ack ack
    reg a_release_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A release ack ack
    reg b_release_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B done ack ack
    reg a_done_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A done ack ack
    reg b_done_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B idle ack ack
    reg a_idle_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A idle ack ack
    reg b_idle_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B active ack ack
    reg a_active_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A active ack ack
    reg b_active_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B clear status ack ack
    reg a_clear_status_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A clear status ack ack
    reg b_clear_status_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B isolate status ack ack
    reg a_isolate_status_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A isolate status ack ack
    reg b_isolate_status_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B release ack ack ack
    reg a_release_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A release ack ack ack
    reg b_release_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B done ack ack ack
    reg a_done_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A done ack ack ack
    reg b_done_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B idle ack ack ack
    reg a_idle_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A idle ack ack ack
    reg b_idle_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B active ack ack ack
    reg a_active_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A active ack ack ack
    reg b_active_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B clear status ack ack ack
    reg a_clear_status_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A clear status ack ack ack
    reg b_clear_status_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B isolate status ack ack ack
    reg a_isolate_status_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A isolate status ack ack ack
    reg b_isolate_status_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B release ack ack ack ack
    reg a_release_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A release ack ack ack ack
    reg b_release_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B done ack ack ack ack
    reg a_done_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A done ack ack ack ack
    reg b_done_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B idle ack ack ack ack
    reg a_idle_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A idle ack ack ack ack
    reg b_idle_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B active ack ack ack ack
    reg a_active_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A active ack ack ack ack
    reg b_active_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B clear status ack ack ack ack
    reg a_clear_status_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A clear status ack ack ack ack
    reg b_clear_status_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B isolate status ack ack ack ack
    reg a_isolate_status_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A isolate status ack ack ack ack
    reg b_isolate_status_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B release ack ack ack ack ack
    reg a_release_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A release ack ack ack ack ack
    reg b_release_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B done ack ack ack ack ack
    reg a_done_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A done ack ack ack ack ack
    reg b_done_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B idle ack ack ack ack ack
    reg a_idle_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A idle ack ack ack ack ack
    reg b_idle_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B active ack ack ack ack ack
    reg a_active_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A active ack ack ack ack ack
    reg b_active_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B clear status ack ack ack ack ack
    reg a_clear_status_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A clear status ack ack ack ack ack
    reg b_clear_status_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B isolate status ack ack ack ack ack
    reg a_isolate_status_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A isolate status ack ack ack ack ack
    reg b_isolate_status_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B release ack ack ack ack ack ack
    reg a_release_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A release ack ack ack ack ack ack
    reg b_release_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B done ack ack ack ack ack ack
    reg a_done_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A done ack ack ack ack ack ack
    reg b_done_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B idle ack ack ack ack ack ack
    reg a_idle_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A idle ack ack ack ack ack ack
    reg b_idle_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B active ack ack ack ack ack ack
    reg a_active_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A active ack ack ack ack ack ack
    reg b_active_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B clear status ack ack ack ack ack ack
    reg a_clear_status_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A clear status ack ack ack ack ack ack
    reg b_clear_status_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B isolate status ack ack ack ack ack ack
    reg a_isolate_status_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A isolate status ack ack ack ack ack ack
    reg b_isolate_status_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B release ack ack ack ack ack ack ack
    reg a_release_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A release ack ack ack ack ack ack ack
    reg b_release_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B done ack ack ack ack ack ack ack
    reg a_done_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A done ack ack ack ack ack ack ack
    reg b_done_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B idle ack ack ack ack ack ack ack
    reg a_idle_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A idle ack ack ack ack ack ack ack
    reg b_idle_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B active ack ack ack ack ack ack ack
    reg a_active_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A active ack ack ack ack ack ack ack
    reg b_active_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B clear status ack ack ack ack ack ack ack
    reg a_clear_status_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A clear status ack ack ack ack ack ack ack
    reg b_clear_status_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B isolate status ack ack ack ack ack ack ack
    reg a_isolate_status_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A isolate status ack ack ack ack ack ack ack
    reg b_isolate_status_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B release ack ack ack ack ack ack ack ack
    reg a_release_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A release ack ack ack ack ack ack ack ack
    reg b_release_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B done ack ack ack ack ack ack ack ack
    reg a_done_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A done ack ack ack ack ack ack ack ack
    reg b_done_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B idle ack ack ack ack ack ack ack ack
    reg a_idle_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A idle ack ack ack ack ack ack ack ack
    reg b_idle_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B active ack ack ack ack ack ack ack ack
    reg a_active_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A active ack ack ack ack ack ack ack ack
    reg b_active_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B clear status ack ack ack ack ack ack ack ack
    reg a_clear_status_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A clear status ack ack ack ack ack ack ack ack
    reg b_clear_status_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B isolate status ack ack ack ack ack ack ack ack
    reg a_isolate_status_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A isolate status ack ack ack ack ack ack ack ack
    reg b_isolate_status_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B release ack ack ack ack ack ack ack ack ack
    reg a_release_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A release ack ack ack ack ack ack ack ack ack
    reg b_release_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B done ack ack ack ack ack ack ack ack ack
    reg a_done_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A done ack ack ack ack ack ack ack ack ack
    reg b_done_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B idle ack ack ack ack ack ack ack ack ack
    reg a_idle_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A idle ack ack ack ack ack ack ack ack ack
    reg b_idle_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B active ack ack ack ack ack ack ack ack ack
    reg a_active_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A active ack ack ack ack ack ack ack ack ack
    reg b_active_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B clear status ack ack ack ack ack ack ack ack ack
    reg a_clear_status_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A clear status ack ack ack ack ack ack ack ack ack
    reg b_clear_status_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B isolate status ack ack ack ack ack ack ack ack ack
    reg a_isolate_status_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A isolate status ack ack ack ack ack ack ack ack ack
    reg b_isolate_status_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B release ack ack ack ack ack ack ack ack ack ack
    reg a_release_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A release ack ack ack ack ack ack ack ack ack ack
    reg b_release_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B done ack ack ack ack ack ack ack ack ack ack
    reg a_done_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A done ack ack ack ack ack ack ack ack ack ack
    reg b_done_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B idle ack ack ack ack ack ack ack ack ack ack
    reg a_idle_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A idle ack ack ack ack ack ack ack ack ack ack
    reg b_idle_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B active ack ack ack ack ack ack ack ack ack ack
    reg a_active_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A active ack ack ack ack ack ack ack ack ack ack
    reg b_active_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B clear status ack ack ack ack ack ack ack ack ack ack
    reg a_clear_status_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A clear status ack ack ack ack ack ack ack ack ack ack
    reg b_clear_status_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B isolate status ack ack ack ack ack ack ack ack ack ack
    reg a_isolate_status_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A isolate status ack ack ack ack ack ack ack ack ack ack
    reg b_isolate_status_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B release ack ack ack ack ack ack ack ack ack ack ack
    reg a_release_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A release ack ack ack ack ack ack ack ack ack ack ack
    reg b_release_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B done ack ack ack ack ack ack ack ack ack ack ack
    reg a_done_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A done ack ack ack ack ack ack ack ack ack ack ack
    reg b_done_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B idle ack ack ack ack ack ack ack ack ack ack ack
    reg a_idle_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A idle ack ack ack ack ack ack ack ack ack ack ack
    reg b_idle_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B active ack ack ack ack ack ack ack ack ack ack ack
    reg a_active_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A active ack ack ack ack ack ack ack ack ack ack ack
    reg b_active_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B clear status ack ack ack ack ack ack ack ack ack ack ack
    reg a_clear_status_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A clear status ack ack ack ack ack ack ack ack ack ack ack
    reg b_clear_status_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B isolate status ack ack ack ack ack ack ack ack ack ack ack
    reg a_isolate_status_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A isolate status ack ack ack ack ack ack ack ack ack ack ack
    reg b_isolate_status_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B release ack ack ack ack ack ack ack ack ack ack ack ack
    reg a_release_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A release ack ack ack ack ack ack ack ack ack ack ack ack
    reg b_release_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B done ack ack ack ack ack ack ack ack ack ack ack ack
    reg a_done_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A done ack ack ack ack ack ack ack ack ack ack ack ack
    reg b_done_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B idle ack ack ack ack ack ack ack ack ack ack ack ack
    reg a_idle_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A idle ack ack ack ack ack ack ack ack ack ack ack ack
    reg b_idle_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B active ack ack ack ack ack ack ack ack ack ack ack ack
    reg a_active_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A active ack ack ack ack ack ack ack ack ack ack ack ack
    reg b_active_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B clear status ack ack ack ack ack ack ack ack ack ack ack ack
    reg a_clear_status_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A clear status ack ack ack ack ack ack ack ack ack ack ack ack
    reg b_clear_status_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B isolate status ack ack ack ack ack ack ack ack ack ack ack ack
    reg a_isolate_status_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A isolate status ack ack ack ack ack ack ack ack ack ack ack ack
    reg b_isolate_status_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B release ack ack ack ack ack ack ack ack ack ack ack ack ack
    reg a_release_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A release ack ack ack ack ack ack ack ack ack ack ack ack ack
    reg b_release_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B done ack ack ack ack ack ack ack ack ack ack ack ack ack
    reg a_done_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A done ack ack ack ack ack ack ack ack ack ack ack ack ack
    reg b_done_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B idle ack ack ack ack ack ack ack ack ack ack ack ack ack
    reg a_idle_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A idle ack ack ack ack ack ack ack ack ack ack ack ack ack
    reg b_idle_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B active ack ack ack ack ack ack ack ack ack ack ack ack ack
    reg a_active_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A active ack ack ack ack ack ack ack ack ack ack ack ack ack
    reg b_active_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B clear status ack ack ack ack ack ack ack ack ack ack ack ack ack
    reg a_clear_status_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A clear status ack ack ack ack ack ack ack ack ack ack ack ack ack
    reg b_clear_status_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B isolate status ack ack ack ack ack ack ack ack ack ack ack ack ack
    reg a_isolate_status_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A isolate status ack ack ack ack ack ack ack ack ack ack ack ack ack
    reg b_isolate_status_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B release ack ack ack ack ack ack ack ack ack ack ack ack ack ack
    reg a_release_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A release ack ack ack ack ack ack ack ack ack ack ack ack ack ack
    reg b_release_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B done ack ack ack ack ack ack ack ack ack ack ack ack ack ack
    reg a_done_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A done ack ack ack ack ack ack ack ack ack ack ack ack ack ack
    reg b_done_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B idle ack ack ack ack ack ack ack ack ack ack ack ack ack ack
    reg a_idle_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A idle ack ack ack ack ack ack ack ack ack ack ack ack ack ack
    reg b_idle_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B active ack ack ack ack ack ack ack ack ack ack ack ack ack ack
    reg a_active_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A active ack ack ack ack ack ack ack ack ack ack ack ack ack ack
    reg b_active_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B clear status ack ack ack ack ack ack ack ack ack ack ack ack ack ack
    reg a_clear_status_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A clear status ack ack ack ack ack ack ack ack ack ack ack ack ack ack
    reg b_clear_status_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for A->B isolate status ack ack ack ack ack ack ack ack ack ack ack ack ack ack
    reg a_isolate_status_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_sync_r [0:SYNC_STAGES-1];
    // Synchronizer registers for B->A isolate status ack ack ack ack ack ack ack ack ack ack ack ack ack ack
    reg b_isolate_status_ack_ack_ack_ack_ack_ack