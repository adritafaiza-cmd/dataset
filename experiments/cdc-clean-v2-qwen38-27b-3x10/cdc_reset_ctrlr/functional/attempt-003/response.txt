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

    // A-side state
    reg [2:0] a_state;
    reg       a_isolate_o_r;
    reg       a_clear_o_r;

    // B-side state
    reg [2:0] b_state;
    reg       b_isolate_o_r;
    reg       b_clear_o_r;

    // A-side sync of B-side state
    reg [2:0] b_state_sync [0:SYNC_STAGES];
    // B-side sync of A-side state
    reg [2:0] a_state_sync [0:SYNC_STAGES];

    // A-side sync of B-side isolate ack
    reg b_isolate_ack_sync [0:SYNC_STAGES];
    // B-side sync of A-side isolate ack
    reg a_isolate_ack_sync [0:SYNC_STAGES];

    // A-side sync of B-side clear ack
    reg b_clear_ack_sync [0:SYNC_STAGES];
    // B-side sync of A-side clear ack
    reg a_clear_ack_sync [0:SYNC_STAGES];

    // A-side sync of B-side clear request
    reg b_clear_req_sync [0:SYNC_STAGES];
    // B-side sync of A-side clear request
    reg a_clear_req_sync [0:SYNC_STAGES];

    // A-side sync of B-side release status
    reg b_release_sync [0:SYNC_STAGES];
    // B-side sync of A-side release status
    reg a_release_sync [0:SYNC_STAGES];

    // A-side sync of B-side done status
    reg b_done_sync [0:SYNC_STAGES];
    // B-side sync of A-side done status
    reg a_done_sync [0:SYNC_STAGES];

    // A-side sync of B-side isolate status
    reg b_isolate_status_sync [0:SYNC_STAGES];
    // B-side sync of A-side isolate status
    reg a_isolate_status_sync [0:SYNC_STAGES];

    // A-side sync of B-side clear status
    reg b_clear_status_sync [0:SYNC_STAGES];
    // B-side sync of A-side clear status
    reg a_clear_status_sync [0:SYNC_STAGES];

    // A-side sync of B-side idle status
    reg b_idle_sync [0:SYNC_STAGES];
    // B-side sync of A-side idle status
    reg a_idle_sync [0:SYNC_STAGES];

    // A-side sync of B-side active status
    reg b_active_sync [0:SYNC_STAGES];
    // B-side sync of A-side active status
    reg a_active_sync [0:SYNC_STAGES];

    // A-side sync of B-side released status
    reg b_released_sync [0:SYNC_STAGES];
    // B-side sync of A-side released status
    reg a_released_sync [0:SYNC_STAGES];

    // A-side sync of B-side clear ack
    reg b_clear_ack_sync2 [0:SYNC_STAGES];
    // B-side sync of A-side clear ack
    reg a_clear_ack_sync2 [0:SYNC_STAGES];

    // A-side sync of B-side isolate ack
    reg b_isolate_ack_sync2 [0:SYNC_STAGES];
    // B-side sync of A-side isolate ack
    reg a_isolate_ack_sync2 [0:SYNC_STAGES];

    // A-side sync of B-side state
    reg [2:0] b_state_sync2 [0:SYNC_STAGES];
    // B-side sync of A-side state
    reg [2:0] a_state_sync2 [0:SYNC_STAGES];

    // A-side sync of B-side clear request
    reg b_clear_req_sync2 [0:SYNC_STAGES];
    // B-side sync of A-side clear request
    reg a_clear_req_sync2 [0:SYNC_STAGES];

    // A-side sync of B-side release status
    reg b_release_sync2 [0:SYNC_STAGES];
    // B-side sync of A-side release status
    reg a_release_sync2 [0:SYNC_STAGES];

    // A-side sync of B-side done status
    reg b_done_sync2 [0:SYNC_STAGES];
    // B-side sync of A-side done status
    reg a_done_sync2 [0:SYNC_STAGES];

    // A-side sync of B-side isolate status
    reg b_isolate_status_sync2 [0:SYNC_STAGES];
    // B-side sync of A-side isolate status
    reg a_isolate_status_sync2 [0:SYNC_STAGES];

    // A-side sync of B-side clear status
    reg b_clear_status_sync2 [0:SYNC_STAGES];
    // B-side sync of A-side clear status
    reg a_clear_status_sync2 [0:SYNC_STAGES];

    // A-side sync of B-side idle status
    reg b_idle_sync2 [0:SYNC_STAGES];
    // B-side sync of A-side idle status
    reg a_idle_sync2 [0:SYNC_STAGES];

    // A-side sync of B-side active status
    reg b_active_sync2 [0:SYNC_STAGES];
    // B-side sync of A-side active status
    reg a_active_sync2 [0:SYNC_STAGES];

    // A-side sync of B-side released status
    reg b_released_sync2 [0:SYNC_STAGES];
    // B-side sync of A-side released status
    reg a_released_sync2 [0:SYNC_STAGES];

    // A-side sync of B-side clear ack
    reg b_clear_ack_sync3 [0:SYNC_STAGES];
    // B-side sync of A-side clear ack
    reg a_clear_ack_sync3 [0:SYNC_STAGES];

    // A-side sync of B-side isolate ack
    reg b_isolate_ack_sync3 [0:SYNC_STAGES];
    // B-side sync of A-side isolate ack
    reg a_isolate_ack_sync3 [0:SYNC_STAGES];

    // A-side sync of B-side state
    reg [2:0] b_state_sync3 [0:SYNC_STAGES];
    // B-side sync of A-side state
    reg [2:0] a_state_sync3 [0:SYNC_STAGES];

    // A-side sync of B-side clear request
    reg b_clear_req_sync3 [0:SYNC_STAGES];
    // B-side sync of A-side clear request
    reg a_clear_req_sync3 [0:SYNC_STAGES];

    // A-side sync of B-side release status
    reg b_release_sync3 [0:SYNC_STAGES];
    // B-side sync of A-side release status
    reg a_release_sync3 [0:SYNC_STAGES];

    // A-side sync of B-side done status
    reg b_done_sync3 [0:SYNC_STAGES];
    // B-side sync of A-side done status
    reg a_done_sync3 [0:SYNC_STAGES];

    // A-side sync of B-side isolate status
    reg b_isolate_status_sync3 [0:SYNC_STAGES];
    // B-side sync of A-side isolate status
    reg a_isolate_status_sync3 [0:SYNC_STAGES];

    // A-side sync of B-side clear status
    reg b_clear_status_sync3 [0:SYNC_STAGES];
    // B-side sync of A-side clear status
    reg a_clear_status_sync3 [0:SYNC_STAGES];

    // A-side sync of B-side idle status
    reg b_idle_sync3 [0:SYNC_STAGES];
    // B-side sync of A-side idle status
    reg a_idle_sync3 [0:SYNC_STAGES];

    // A-side sync of B-side active status
    reg b_active_sync3 [0:SYNC_STAGES];
    // B-side sync of A-side active status
    reg a_active_sync3 [0:SYNC_STAGES];

    // A-side sync of B-side released status
    reg b_released_sync3 [0:SYNC_STAGES];
    // B-side sync of A-side released status
    reg a_released_sync3 [0:SYNC_STAGES];

    // A-side sync of B-side clear ack
    reg b_clear_ack_sync4 [0:SYNC_STAGES];
    // B-side sync of A-side clear ack
    reg a_clear_ack_sync4 [0:SYNC_STAGES];

    // A-side sync of B-side isolate ack
    reg b_isolate_ack_sync4 [0:SYNC_STAGES];
    // B-side sync of A-side isolate ack
    reg a_isolate_ack_sync4 [0:SYNC_STAGES];

    // A-side sync of B-side state
    reg [2:0] b_state_sync4 [0:SYNC_STAGES];
    // B-side sync of A-side state
    reg [2:0] a_state_sync4 [0:SYNC_STAGES];

    // A-side sync of B-side clear request
    reg b_clear_req_sync4 [0:SYNC_STAGES];
    // B-side sync of A-side clear request
    reg a_clear_req_sync4 [0:SYNC_STAGES];

    // A-side sync of B-side release status
    reg b_release_sync4 [0:SYNC_STAGES];
    // B-side sync of A-side release status
    reg a_release_sync4 [0:SYNC_STAGES];

    // A-side sync of B-side done status
    reg b_done_sync4 [0:SYNC_STAGES];
    // B-side sync of A-side done status
    reg a_done_sync4 [0:SYNC_STAGES];

    // A-side sync of B-side isolate status
    reg b_isolate_status_sync4 [0:SYNC_STAGES];
    // B-side sync of A-side isolate status
    reg a_isolate_status_sync4 [0:SYNC_STAGES];

    // A-side sync of B-side clear status
    reg b_clear_status_sync4 [0:SYNC_STAGES];
    // B-side sync of A-side clear status
    reg a_clear_status_sync4 [0:SYNC_STAGES];

    // A-side sync of B-side idle status
    reg b_idle_sync4 [0:SYNC_STAGES];
    // B-side sync of A-side idle status
    reg a_idle_sync4 [0:SYNC_STAGES];

    // A-side sync of B-side active status
    reg b_active_sync4 [0:SYNC_STAGES];
    // B-side sync of A-side active status
    reg a_active_sync4 [0:SYNC_STAGES];

    // A-side sync of B-side released status
    reg b_released_sync4 [0:SYNC_STAGES];
    // B-side sync of A-side released status
    reg a_released_sync4 [0:SYNC_STAGES];

    // A-side sync of B-side clear ack
    reg b_clear_ack_sync5 [0:SYNC_STAGES];
    // B-side sync of A-side clear ack
    reg a_clear_ack_sync5 [0:SYNC_STAGES];

    // A-side sync of B-side isolate ack
    reg b_isolate_ack_sync5 [0:SYNC_STAGES];
    // B-side sync of A-side isolate ack
    reg a_isolate_ack_sync5 [0:SYNC_STAGES];

    // A-side sync of B-side state
    reg [2:0] b_state_sync5 [0:SYNC_STAGES];
    // B-side sync of A-side state
    reg [2:0] a_state_sync5 [0:SYNC_STAGES];

    // A-side sync of B-side clear request
    reg b_clear_req_sync5 [0:SYNC_STAGES];
    // B-side sync of A-side clear request
    reg a_clear_req_sync5 [0:SYNC_STAGES];

    // A-side sync of B-side release status
    reg b_release_sync5 [0:SYNC_STAGES];
    // B-side sync of A-side release status
    reg a_release_sync5 [0:SYNC_STAGES];

    // A-side sync of B-side done status
    reg b_done_sync5 [0:SYNC_STAGES];
    // B-side sync of A-side done status
    reg a_done_sync5 [0:SYNC_STAGES];

    // A-side sync of B-side isolate status
    reg b_isolate_status_sync5 [0:SYNC_STAGES];
    // B-side sync of A-side isolate status
    reg a_isolate_status_sync5 [0:SYNC_STAGES];

    // A-side sync of B-side clear status
    reg b_clear_status_sync5 [0:SYNC_STAGES];
    // B-side sync of A-side clear status
    reg a_clear_status_sync5 [0:SYNC_STAGES];

    // A-side sync of B-side idle status
    reg b_idle_sync5 [0:SYNC_STAGES];
    // B-side sync of A-side idle status
    reg a_idle_sync5 [0:SYNC_STAGES];

    // A-side sync of B-side active status
    reg b_active_sync5 [0:SYNC_STAGES];
    // B-side sync of A-side active status
    reg a_active_sync5 [0:SYNC_STAGES];

    // A-side sync of B-side released status
    reg b_released_sync5 [0:SYNC_STAGES];
    // B-side sync of A-side released status
    reg a_released_sync5 [0:SYNC_STAGES];

    // A-side sync of B-side clear ack
    reg b_clear_ack_sync6 [0:SYNC_STAGES];
    // B-side sync of A-side clear ack
    reg a_clear_ack_sync6 [0:SYNC_STAGES];

    // A-side sync of B-side isolate ack
    reg b_isolate_ack_sync6 [0:SYNC_STAGES];
    // B-side sync of A-side isolate ack
    reg a_isolate_ack_sync6 [0:SYNC_STAGES];

    // A-side sync of B-side state
    reg [2:0] b_state_sync6 [0:SYNC_STAGES];
    // B-side sync of A-side state
    reg [2:0] a_state_sync6 [0:SYNC_STAGES];

    // A-side sync of B-side clear request
    reg b_clear_req_sync6 [0:SYNC_STAGES];
    // B-side sync of A-side clear request
    reg a_clear_req_sync6 [0:SYNC_STAGES];

    // A-side sync of B-side release status
    reg b_release_sync6 [0:SYNC_STAGES];
    // B-side sync of A-side release status
    reg a_release_sync6 [0:SYNC_STAGES];

    // A-side sync of B-side done status
    reg b_done_sync6 [0:SYNC_STAGES];
    // B-side sync of A-side done status
    reg a_done_sync6 [0:SYNC_STAGES];

    // A-side sync of B-side isolate status
    reg b_isolate_status_sync6 [0:SYNC_STAGES];
    // B-side sync of A-side isolate status
    reg a_isolate_status_sync6 [0:SYNC_STAGES];

    // A-side sync of B-side clear status
    reg b_clear_status_sync6 [0:SYNC_STAGES];
    // B-side sync of A-side clear status
    reg a_clear_status_sync6 [0:SYNC_STAGES];

    // A-side sync of B-side idle status
    reg b_idle_sync6 [0:SYNC_STAGES];
    // B-side sync of A-side idle status
    reg a_idle_sync6 [0:SYNC_STAGES];

    // A-side sync of B-side active status
    reg b_active_sync6 [0:SYNC_STAGES];
    // B-side sync of A-side active status
    reg a_active_sync6 [0:SYNC_STAGES];

    // A-side sync of B-side released status
    reg b_released_sync6 [0:SYNC_STAGES];
    // B-side sync of A-side released status
    reg a_released_sync6 [0:SYNC_STAGES];

    // A-side sync of B-side clear ack
    reg b_clear_ack_sync7 [0:SYNC_STAGES];
    // B-side sync of A-side clear ack
    reg a_clear_ack_sync7 [0:SYNC_STAGES];

    // A-side sync of B-side isolate ack
    reg b_isolate_ack_sync7 [0:SYNC_STAGES];
    // B-side sync of A-side isolate ack
    reg a_isolate_ack_sync7 [0:SYNC_STAGES];

    // A-side sync of B-side state
    reg [2:0] b_state_sync7 [0:SYNC_STAGES];
    // B-side sync of A-side state
    reg [2:0] a_state_sync7 [0:SYNC_STAGES];

    // A-side sync of B-side clear request
    reg b_clear_req_sync7 [0:SYNC_STAGES];
    // B-side sync of A-side clear request
    reg a_clear_req_sync7 [0:SYNC_STAGES];

    // A-side sync of B-side release status
    reg b_release_sync7 [0:SYNC_STAGES];
    // B-side sync of A-side release status
    reg a_release_sync7 [0:SYNC_STAGES];

    // A-side sync of B-side done status
    reg b_done_sync7 [0:SYNC_STAGES];
    // B-side sync of A-side done status
    reg a_done_sync7 [0:SYNC_STAGES];

    // A-side sync of B-side isolate status
    reg b_isolate_status_sync7 [0:SYNC_STAGES];
    // B-side sync of A-side isolate status
    reg a_isolate_status_sync7 [0:SYNC_STAGES];

    // A-side sync of B-side clear status
    reg b_clear_status_sync7 [0:SYNC_STAGES];
    // B-side sync of A-side clear status
    reg a_clear_status_sync7 [0:SYNC_STAGES];

    // A-side sync of B-side idle status
    reg b_idle_sync7 [0:SYNC_STAGES];
    // B-side sync of A-side idle status
    reg a_idle_sync7 [0:SYNC_STAGES];

    // A-side sync of B-side active status
    reg b_active_sync7 [0:SYNC_STAGES];
    // B-side sync of A-side active status
    reg a_active_sync7 [0:SYNC_STAGES];

    // A-side sync of B-side released status
    reg b_released_sync7 [0:SYNC_STAGES];
    // B-side sync of A-side released status
    reg a_released_sync7 [0:SYNC_STAGES];

    // A-side sync of B-side clear ack
    reg b_clear_ack_sync8 [0:SYNC_STAGES];
    // B-side sync of A-side clear ack
    reg a_clear_ack_sync8 [0:SYNC_STAGES];

    // A-side sync of B-side isolate ack
    reg b_isolate_ack_sync8 [0:SYNC_STAGES];
    // B-side sync of A-side isolate ack
    reg a_isolate_ack_sync8 [0:SYNC_STAGES];

    // A-side sync of B-side state
    reg [2:0] b_state_sync8 [0:SYNC_STAGES];
    // B-side sync of A-side state
    reg [2:0] a_state_sync8 [0:SYNC_STAGES];

    // A-side sync of B-side clear request
    reg b_clear_req_sync8 [0:SYNC_STAGES];
    // B-side sync of A-side clear request
    reg a_clear_req_sync8 [0:SYNC_STAGES];

    // A-side sync of B-side release status
    reg b_release_sync8 [0:SYNC_STAGES];
    // B-side sync of A-side release status
    reg a_release_sync8 [0:SYNC_STAGES];

    // A-side sync of B-side done status
    reg b_done_sync8 [0:SYNC_STAGES];
    // B-side sync of A-side done status
    reg a_done_sync8 [0:SYNC_STAGES];

    // A-side sync of B-side isolate status
    reg b_isolate_status_sync8 [0:SYNC_STAGES];
    // B-side sync of A-side isolate status
    reg a_isolate_status_sync8 [0:SYNC_STAGES];

    // A-side sync of B-side clear status
    reg b_clear_status_sync8 [0:SYNC_STAGES];
    // B-side sync of A-side clear status
    reg a_clear_status_sync8 [0:SYNC_STAGES];

    // A-side sync of B-side idle status
    reg b_idle_sync8 [0:SYNC_STAGES];
    // B-side sync of A-side idle status
    reg a_idle_sync8 [0:SYNC_STAGES];

    // A-side sync of B-side active status
    reg b_active_sync8 [0:SYNC_STAGES];
    // B-side sync of A-side active status
    reg a_active_sync8 [0:SYNC_STAGES];

    // A-side sync of B-side released status
    reg b_released_sync8 [0:SYNC_STAGES];
    // B-side sync of A-side released status
    reg a_released_sync8 [0:SYNC_STAGES];

    // A-side sync of B-side clear ack
    reg b_clear_ack_sync9 [0:SYNC_STAGES];
    // B-side sync of A-side clear ack
    reg a_clear_ack_sync9 [0:SYNC_STAGES];

    // A-side sync of B-side isolate ack
    reg b_isolate_ack_sync9 [0:SYNC_STAGES];
    // B-side sync of A-side isolate ack
    reg a_isolate_ack_sync9 [0:SYNC_STAGES];

    // A-side sync of B-side state
    reg [2:0] b_state_sync9 [0:SYNC_STAGES];
    // B-side sync of A-side state
    reg [2:0] a_state_sync9 [0:SYNC_STAGES];

    // A-side sync of B-side clear request
    reg b_clear_req_sync9 [0:SYNC_STAGES];
    // B-side sync of A-side clear request
    reg a_clear_req_sync9 [0:SYNC_STAGES];

    // A-side sync of B-side release status
    reg b_release_sync9 [0:SYNC_STAGES];
    // B-side sync of A-side release status
    reg a_release_sync9 [0:SYNC_STAGES];

    // A-side sync of B-side done status
    reg b_done_sync9 [0:SYNC_STAGES];
    // B-side sync of A-side done status
    reg a_done_sync9 [0:SYNC_STAGES];

    // A-side sync of B-side isolate status
    reg b_isolate_status_sync9 [0:SYNC_STAGES];
    // B-side sync of A-side isolate status
    reg a_isolate_status_sync9 [0:SYNC_STAGES];

    // A-side sync of B-side clear status
    reg b_clear_status_sync9 [0:SYNC_STAGES];
    // B-side sync of A-side clear status
    reg a_clear_status_sync9 [0:SYNC_STAGES];

    // A-side sync of B-side idle status
    reg b_idle_sync9 [0:SYNC_STAGES];
    // B-side sync of A-side idle status
    reg a_idle_sync9 [0:SYNC_STAGES];

    // A-side sync of B-side active status
    reg b_active_sync9 [0:SYNC_STAGES];
    // B-side sync of A-side active status
    reg a_active_sync9 [0:SYNC_STAGES];

    // A-side sync of B-side released status
    reg b_released_sync9 [0:SYNC_STAGES];
    // B-side sync of A-side released status
    reg a_released_sync9 [0:SYNC_STAGES];

    // A-side sync of B-side clear ack
    reg b_clear_ack_sync10 [0:SYNC_STAGES];
    // B-side sync of A-side clear ack
    reg a_clear_ack_sync10 [0:SYNC_STAGES];

    // A-side sync of B-side isolate ack
    reg b_isolate_ack_sync10 [0:SYNC_STAGES];
    // B-side sync of A-side isolate ack
    reg a_isolate_ack_sync10 [0:SYNC_STAGES];

    // A-side sync of B-side state
    reg [2:0] b_state_sync10 [0:SYNC_STAGES];
    // B-side sync of A-side state
    reg [2:0] a_state_sync10 [0:SYNC_STAGES];

    // A-side sync of B-side clear request
    reg b_clear_req_sync10 [0:SYNC_STAGES];
    // B-side sync of A-side clear request
    reg a_clear_req_sync10 [0:SYNC_STAGES];

    // A-side sync of B-side release status
    reg b_release_sync10 [0:SYNC_STAGES];
    // B-side sync of A-side release status
    reg a_release_sync10 [0:SYNC_STAGES];

    // A-side sync of B-side done status
    reg b_done_sync10 [0:SYNC_STAGES];
    // B-side sync of A-side done status
    reg a_done_sync10 [0:SYNC_STAGES];

    // A-side sync of B-side isolate status
    reg b_isolate_status_sync10 [0:SYNC_STAGES];
    // B-side sync of A-side isolate status
    reg a_isolate_status_sync10 [0:SYNC_STAGES];

    // A-side sync of B-side clear status
    reg b_clear_status_sync10 [0:SYNC_STAGES];
    // B-side sync of A-side clear status
    reg a_clear_status_sync10 [0:SYNC_STAGES];

    // A-side sync of B-side idle status
    reg b_idle_sync10 [0:SYNC_STAGES];
    // B-side sync of A-side idle status
    reg a_idle_sync10 [0:SYNC_STAGES];

    // A-side sync of B-side active status
    reg b_active_sync10 [0:SYNC_STAGES];
    // B-side sync of A-side active status
    reg a_active_sync10 [0:SYNC_STAGES];

    // A-side sync of B-side released status
    reg b_released_sync10 [0:SYNC_STAGES];
    // B-side sync of A-side released status
    reg a_released_sync10 [0:SYNC_STAGES];

    // A-side sync of B-side clear ack
    reg b_clear_ack_sync11 [0:SYNC_STAGES];
    // B-side sync of A-side clear ack
    reg a_clear_ack_sync11 [0:SYNC_STAGES];

    // A-side sync of B-side isolate ack
    reg b_isolate_ack_sync11 [0:SYNC_STAGES];
    // B-side sync of A-side isolate ack
    reg a_isolate_ack_sync11 [0:SYNC_STAGES];

    // A-side sync of B-side state
    reg [2:0] b_state_sync11 [0:SYNC_STAGES];
    // B-side sync of A-side state
    reg [2:0] a_state_sync11 [0:SYNC_STAGES];

    // A-side sync of B-side clear request
    reg b_clear_req_sync11 [0:SYNC_STAGES];
    // B-side sync of A-side clear request
    reg a_clear_req_sync11 [0:SYNC_STAGES];

    // A-side sync of B-side release status
    reg b_release_sync11 [0:SYNC_STAGES];
    // B-side sync of A-side release status
    reg a_release_sync11 [0:SYNC_STAGES];

    // A-side sync of B-side done status
    reg b_done_sync11 [0:SYNC_STAGES];
    // B-side sync of A-side done status
    reg a_done_sync11 [0:SYNC_STAGES];

    // A-side sync of B-side isolate status
    reg b_isolate_status_sync11 [0:SYNC_STAGES];
    // B-side sync of A-side isolate status
    reg a_isolate_status_sync11 [0:SYNC_STAGES];

    // A-side sync of B-side clear status
    reg b_clear_status_sync11 [0:SYNC_STAGES];
    // B-side sync of A-side clear status
    reg a_clear_status_sync11 [0:SYNC_STAGES];

    // A-side sync of B-side idle status
    reg b_idle_sync11 [0:SYNC_STAGES];
    // B-side sync of A-side idle status
    reg a_idle_sync11 [0:SYNC_STAGES];

    // A-side sync of B-side active status
    reg b_active_sync11 [0:SYNC_STAGES];
    // B-side sync of A-side active status
    reg a_active_sync11 [0:SYNC_STAGES];

    // A-side sync of B-side released status
    reg b_released_sync11 [0:SYNC_STAGES];
    // B-side sync of A-side released status
    reg a_released_sync11 [0:SYNC_STAGES];

    // A-side sync of B-side clear ack
    reg b_clear_ack_sync12 [0:SYNC_STAGES];
    // B-side sync of A-side clear ack
    reg a_clear_ack_sync12 [0:SYNC_STAGES];

    // A-side sync of B-side isolate ack
    reg b_isolate_ack_sync12 [0:SYNC_STAGES];
    // B-side sync of A-side isolate ack
    reg a_isolate_ack_sync12 [0:SYNC_STAGES];

    // A-side sync of B-side state
    reg [2:0] b_state_sync12 [0:SYNC_STAGES];
    // B-side sync of A-side state
    reg [2:0] a_state_sync12 [0:SYNC_STAGES];

    // A-side sync of B-side clear request
    reg b_clear_req_sync12 [0:SYNC_STAGES];
    // B-side sync of A-side clear request
    reg a_clear_req_sync12 [0:SYNC_STAGES];

    // A-side sync of B-side release status
    reg b_release_sync12 [0:SYNC_STAGES];
    // B-side sync of A-side release status
    reg a_release_sync12 [0:SYNC_STAGES];

    // A-side sync of B-side done status
    reg b_done_sync12 [0:SYNC_STAGES];
    // B-side sync of A-side done status
    reg a_done_sync12 [0:SYNC_STAGES];

    // A-side sync of B-side isolate status
    reg b_isolate_status_sync12 [0:SYNC_STAGES];
    // B-side sync of A-side isolate status
    reg a_isolate_status_sync12 [0:SYNC_STAGES];

    // A-side sync of B-side clear status
    reg b_clear_status_sync12 [0:SYNC_STAGES];
    // B-side sync of A-side clear status
    reg a_clear_status_sync12 [0:SYNC_STAGES];

    // A-side sync of B-side idle status
    reg b_idle_sync12 [0:SYNC_STAGES];
    // B-side sync of A-side idle status
    reg a_idle_sync12 [0:SYNC_STAGES];

    // A-side sync of B-side active status
    reg b_active_sync12 [0:SYNC_STAGES];
    // B-side sync of A-side active status
    reg a_active_sync12 [0:SYNC_STAGES];

    // A-side sync of B-side released status
    reg b_released_sync12 [0:SYNC_STAGES];
    // B-side sync of A-side released status
    reg a_released_sync12 [0:SYNC_STAGES];

    // A-side sync of B-side clear ack
    reg b_clear_ack_sync13 [0:SYNC_STAGES];
    // B-side sync of A-side clear ack
    reg a_clear_ack_sync13 [0:SYNC_STAGES];

    // A-side sync of B-side isolate ack
    reg b_isolate_ack_sync13 [0:SYNC_STAGES];
    // B-side sync of A-side isolate ack
    reg a_isolate_ack_sync13 [0:SYNC_STAGES];

    // A-side sync of B-side state
    reg [2:0] b_state_sync13 [0:SYNC_STAGES];
    // B-side sync of A-side state
    reg [2:0] a_state_sync13 [0:SYNC_STAGES];

    // A-side sync of B-side clear request
    reg b_clear_req_sync13 [0:SYNC_STAGES];
    // B-side sync of A-side clear request
    reg a_clear_req_sync13 [0:SYNC_STAGES];

    // A-side sync of B-side release status
    reg b_release_sync13 [0:SYNC_STAGES];
    // B-side sync of A-side release status
    reg a_release_sync13 [0:SYNC_STAGES];

    // A-side sync of B-side done status
    reg b_done_sync13 [0:SYNC_STAGES];
    // B-side sync of A-side done status
    reg a_done_sync13 [0:SYNC_STAGES];

    // A-side sync of B-side isolate status
    reg b_isolate_status_sync13 [0:SYNC_STAGES];
    // B-side sync of A-side isolate status
    reg a_isolate_status_sync13 [0:SYNC_STAGES];

    // A-side sync of B-side clear status
    reg b_clear_status_sync13 [0:SYNC_STAGES];
    // B-side sync of A-side clear status
    reg a_clear_status_sync13 [0:SYNC_STAGES];

    // A-side sync of B-side idle status
    reg b_idle_sync13 [0:SYNC_STAGES];
    // B-side sync of A-side idle status
    reg a_idle_sync13 [0:SYNC_STAGES];

    // A-side sync of B-side active status
    reg b_active_sync13 [0:SYNC_STAGES];
    // B-side sync of A-side active status
    reg a_active_sync13 [0:SYNC_STAGES];

    // A-side sync of B-side released status
    reg b_released_sync13 [0:SYNC_STAGES];
    // B-side sync of A-side released status
    reg a_released_sync13 [0:SYNC_STAGES];

    // A-side sync of B-side clear ack
    reg b_clear_ack_sync14 [0:SYNC_STAGES];
    // B-side sync of A-side clear ack
    reg a_clear_ack_sync14 [0:SYNC_STAGES];

    // A-side sync of B-side isolate ack
    reg b_isolate_ack_sync14 [0:SYNC_STAGES];
    // B-side sync of A-side isolate ack
    reg a_isolate_ack_sync14 [0:SYNC_STAGES];

    // A-side sync of B-side state
    reg [2:0] b_state_sync14 [0:SYNC_STAGES];
    // B-side sync of A-side state
    reg [2:0] a_state_sync14 [0:SYNC_STAGES];

    // A-side sync of B-side clear request
    reg b_clear_req_sync14 [0:SYNC_STAGES];
    // B-side sync of A-side clear request
    reg a_clear_req_sync14 [0:SYNC_STAGES];

    // A-side sync of B-side release status
    reg b_release_sync14 [0:SYNC_STAGES];
    // B-side sync of A-side release status
    reg a_release_sync14 [0:SYNC_STAGES];

    // A-side sync of B-side done status
    reg b_done_sync14 [0:SYNC_STAGES];
    // B-side sync of A-side done status
    reg a_done_sync14 [0:SYNC_STAGES];

    // A-side sync of B-side isolate status
    reg b_isolate_status_sync14 [0:SYNC_STAGES];
    // B-side sync of A-side isolate status
    reg a_isolate_status_sync14