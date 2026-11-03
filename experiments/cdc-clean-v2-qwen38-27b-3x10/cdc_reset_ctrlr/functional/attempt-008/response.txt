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

    // A-side sync of B-side isolate output
    reg       b_isolate_sync [0:SYNC_STAGES];
    // B-side sync of A-side isolate output
    reg       a_isolate_sync [0:SYNC_STAGES];

    // A-side sync of B-side clear output
    reg       b_clear_sync [0:SYNC_STAGES];
    // B-side sync of A-side clear output
    reg       a_clear_sync [0:SYNC_STAGES];

    // A-side sync of B-side clear ack
    reg       b_clear_ack_sync [0:SYNC_STAGES];
    // B-side sync of A-side clear ack
    reg       a_clear_ack_sync [0:SYNC_STAGES];

    // A-side sync of B-side isolate ack
    reg       b_isolate_ack_sync [0:SYNC_STAGES];
    // B-side sync of A-side isolate ack
    reg       a_isolate_ack_sync [0:SYNC_STAGES];

    // A-side sync of B-side clear request
    reg       b_clear_req_sync [0:SYNC_STAGES];
    // B-side sync of A-side clear request
    reg       a_clear_req_sync [0:SYNC_STAGES];

    // A-side sync of B-side release status
    reg       b_release_sync [0:SYNC_STAGES];
    // B-side sync of A-side release status
    reg       a_release_sync [0:SYNC_STAGES];

    // A-side sync of B-side done status
    reg       b_done_sync [0:SYNC_STAGES];
    // B-side sync of A-side done status
    reg       a_done_sync [0:SYNC_STAGES];

    // A-side sync of B-side isolate status
    reg       b_isolate_status_sync [0:SYNC_STAGES];
    // B-side sync of A-side isolate status
    reg       a_isolate_status_sync [0:SYNC_STAGES];

    // A-side sync of B-side clear status
    reg       b_clear_status_sync [0:SYNC_STAGES];
    // B-side sync of A-side clear status
    reg       a_clear_status_sync [0:SYNC_STAGES];

    // A-side sync of B-side idle status
    reg       b_idle_sync [0:SYNC_STAGES];
    // B-side sync of A-side idle status
    reg       a_idle_sync [0:SYNC_STAGES];

    // A-side sync of B-side active status
    reg       b_active_sync [0:SYNC_STAGES];
    // B-side sync of A-side active status
    reg       a_active_sync [0:SYNC_STAGES];

    // A-side sync of B-side released status
    reg       b_released_sync [0:SYNC_STAGES];
    // B-side sync of A-side released status
    reg       a_released_sync [0:SYNC_STAGES];

    // A-side sync of B-side peer progress
    reg [2:0] b_peer_progress_sync [0:SYNC_STAGES];
    // B-side sync of A-side peer progress
    reg [2:0] a_peer_progress_sync [0:SYNC_STAGES];

    // A-side sync of B-side sequence complete
    reg       b_seq_complete_sync [0:SYNC_STAGES];
    // B-side sync of A-side sequence complete
    reg       a_seq_complete_sync [0:SYNC_STAGES];

    // A-side sync of B-side isolate ack
    reg       b_isolate_ack_sync_r [0:SYNC_STAGES];
    // B-side sync of A-side isolate ack
    reg       a_isolate_ack_sync_r [0:SYNC_STAGES];

    // A-side sync of B-side clear ack
    reg       b_clear_ack_sync_r [0:SYNC_STAGES];
    // B-side sync of A-side clear ack
    reg       a_clear_ack_sync_r [0:SYNC_STAGES];

    // A-side sync of B-side isolate output
    reg       b_isolate_out_sync [0:SYNC_STAGES];
    // B-side sync of A-side isolate output
    reg       a_isolate_out_sync [0:SYNC_STAGES];

    // A-side sync of B-side clear output
    reg       b_clear_out_sync [0:SYNC_STAGES];
    // B-side sync of A-side clear output
    reg       a_clear_out_sync [0:SYNC_STAGES];

    // A-side sync of B-side state
    reg [2:0] b_state_sync_r [0:SYNC_STAGES];
    // B-side sync of A-side state
    reg [2:0] a_state_sync_r [0:SYNC_STAGES];

    // A-side sync of B-side clear request
    reg       b_clear_req_sync_r [0:SYNC_STAGES];
    // B-side sync of A-side clear request
    reg       a_clear_req_sync_r [0:SYNC_STAGES];

    // A-side sync of B-side release status
    reg       b_release_status_sync [0:SYNC_STAGES];
    // B-side sync of A-side release status
    reg       a_release_status_sync [0:SYNC_STAGES];

    // A-side sync of B-side done status
    reg       b_done_status_sync [0:SYNC_STAGES];
    // B-side sync of A-side done status
    reg       a_done_status_sync [0:SYNC_STAGES];

    // A-side sync of B-side isolate status
    reg       b_isolate_status_sync_r [0:SYNC_STAGES];
    // B-side sync of A-side isolate status
    reg       a_isolate_status_sync_r [0:SYNC_STAGES];

    // A-side sync of B-side clear status
    reg       b_clear_status_sync_r [0:SYNC_STAGES];
    // B-side sync of A-side clear status
    reg       a_clear_status_sync_r [0:SYNC_STAGES];

    // A-side sync of B-side idle status
    reg       b_idle_status_sync [0:SYNC_STAGES];
    // B-side sync of A-side idle status
    reg       a_idle_status_sync [0:SYNC_STAGES];

    // A-side sync of B-side active status
    reg       b_active_status_sync [0:SYNC_STAGES];
    // B-side sync of A-side active status
    reg       a_active_status_sync [0:SYNC_STAGES];

    // A-side sync of B-side released status
    reg       b_released_status_sync [0:SYNC_STAGES];
    // B-side sync of A-side released status
    reg       a_released_status_sync [0:SYNC_STAGES];

    // A-side sync of B-side peer progress
    reg [2:0] b_peer_progress_sync_r [0:SYNC_STAGES];
    // B-side sync of A-side peer progress
    reg [2:0] a_peer_progress_sync_r [0:SYNC_STAGES];

    // A-side sync of B-side sequence complete
    reg       b_seq_complete_sync_r [0:SYNC_STAGES];
    // B-side sync of A-side sequence complete
    reg       a_seq_complete_sync_r [0:SYNC_STAGES];

    // A-side sync of B-side isolate ack
    reg       b_isolate_ack_sync_rr [0:SYNC_STAGES];
    // B-side sync of A-side isolate ack
    reg       a_isolate_ack_sync_rr [0:SYNC_STAGES];

    // A-side sync of B-side clear ack
    reg       b_clear_ack_sync_rr [0:SYNC_STAGES];
    // B-side sync of A-side clear ack
    reg       a_clear_ack_sync_rr [0:SYNC_STAGES];

    // A-side sync of B-side isolate output
    reg       b_isolate_out_sync_r [0:SYNC_STAGES];
    // B-side sync of A-side isolate output
    reg       a_isolate_out_sync_r [0:SYNC_STAGES];

    // A-side sync of B-side clear output
    reg       b_clear_out_sync_r [0:SYNC_STAGES];
    // B-side sync of A-side clear output
    reg       a_clear_out_sync_r [0:SYNC_STAGES];

    // A-side sync of B-side state
    reg [2:0] b_state_sync_rr [0:SYNC_STAGES];
    // B-side sync of A-side state
    reg [2:0] a_state_sync_rr [0:SYNC_STAGES];

    // A-side sync of B-side clear request
    reg       b_clear_req_sync_rr [0:SYNC_STAGES];
    // B-side sync of A-side clear request
    reg       a_clear_req_sync_rr [0:SYNC_STAGES];

    // A-side sync of B-side release status
    reg       b_release_status_sync_r [0:SYNC_STAGES];
    // B-side sync of A-side release status
    reg       a_release_status_sync_r [0:SYNC_STAGES];

    // A-side sync of B-side done status
    reg       b_done_status_sync_r [0:SYNC_STAGES];
    // B-side sync of A-side done status
    reg       a_done_status_sync_r [0:SYNC_STAGES];

    // A-side sync of B-side isolate status
    reg       b_isolate_status_sync_rr [0:SYNC_STAGES];
    // B-side sync of A-side isolate status
    reg       a_isolate_status_sync_rr [0:SYNC_STAGES];

    // A-side sync of B-side clear status
    reg       b_clear_status_sync_rr [0:SYNC_STAGES];
    // B-side sync of A-side clear status
    reg       a_clear_status_sync_rr [0:SYNC_STAGES];

    // A-side sync of B-side idle status
    reg       b_idle_status_sync_r [0:SYNC_STAGES];
    // B-side sync of A-side idle status
    reg       a_idle_status_sync_r [0:SYNC_STAGES];

    // A-side sync of B-side active status
    reg       b_active_status_sync_r [0:SYNC_STAGES];
    // B-side sync of A-side active status
    reg       a_active_status_sync_r [0:SYNC_STAGES];

    // A-side sync of B-side released status
    reg       b_released_status_sync_r [0:SYNC_STAGES];
    // B-side sync of A-side released status
    reg       a_released_status_sync_r [0:SYNC_STAGES];

    // A-side sync of B-side peer progress
    reg [2:0] b_peer_progress_sync_rr [0:SYNC_STAGES];
    // B-side sync of A-side peer progress
    reg [2:0] a_peer_progress_sync_rr [0:SYNC_STAGES];

    // A-side sync of B-side sequence complete
    reg       b_seq_complete_sync_rr [0:SYNC_STAGES];
    // B-side sync of A-side sequence complete
    reg       a_seq_complete_sync_rr [0:SYNC_STAGES];

    // A-side sync of B-side isolate ack
    reg       b_isolate_ack_sync_rrr [0:SYNC_STAGES];
    // B-side sync of A-side isolate ack
    reg       a_isolate_ack_sync_rrr [0:SYNC_STAGES];

    // A-side sync of B-side clear ack
    reg       b_clear_ack_sync_rrr [0:SYNC_STAGES];
    // B-side sync of A-side clear ack
    reg       a_clear_ack_sync_rrr [0:SYNC_STAGES];

    // A-side sync of B-side isolate output
    reg       b_isolate_out_sync_rr [0:SYNC_STAGES];
    // B-side sync of A-side isolate output
    reg       a_isolate_out_sync_rr [0:SYNC_STAGES];

    // A-side sync of B-side clear output
    reg       b_clear_out_sync_rr [0:SYNC_STAGES];
    // B-side sync of A-side clear output
    reg       a_clear_out_sync_rr [0:SYNC_STAGES];

    // A-side sync of B-side state
    reg [2:0] b_state_sync_rrr [0:SYNC_STAGES];
    // B-side sync of A-side state
    reg [2:0] a_state_sync_rrr [0:SYNC_STAGES];

    // A-side sync of B-side clear request
    reg       b_clear_req_sync_rrr [0:SYNC_STAGES];
    // B-side sync of A-side clear request
    reg       a_clear_req_sync_rrr [0:SYNC_STAGES];

    // A-side sync of B-side release status
    reg       b_release_status_sync_rr [0:SYNC_STAGES];
    // B-side sync of A-side release status
    reg       a_release_status_sync_rr [0:SYNC_STAGES];

    // A-side sync of B-side done status
    reg       b_done_status_sync_rr [0:SYNC_STAGES];
    // B-side sync of A-side done status
    reg       a_done_status_sync_rr [0:SYNC_STAGES];

    // A-side sync of B-side isolate status
    reg       b_isolate_status_sync_rrr [0:SYNC_STAGES];
    // B-side sync of A-side isolate status
    reg       a_isolate_status_sync_rrr [0:SYNC_STAGES];

    // A-side sync of B-side clear status
    reg       b_clear_status_sync_rrr [0:SYNC_STAGES];
    // B-side sync of A-side clear status
    reg       a_clear_status_sync_rrr [0:SYNC_STAGES];

    // A-side sync of B-side idle status
    reg       b_idle_status_sync_rr [0:SYNC_STAGES];
    // B-side sync of A-side idle status
    reg       a_idle_status_sync_rr [0:SYNC_STAGES];

    // A-side sync of B-side active status
    reg       b_active_status_sync_rr [0:SYNC_STAGES];
    // B-side sync of A-side active status
    reg       a_active_status_sync_rr [0:SYNC_STAGES];

    // A-side sync of B-side released status
    reg       b_released_status_sync_rr [0:SYNC_STAGES];
    // B-side sync of A-side released status
    reg       a_released_status_sync_rr [0:SYNC_STAGES];

    // A-side sync of B-side peer progress
    reg [2:0] b_peer_progress_sync_rrr [0:SYNC_STAGES];
    // B-side sync of A-side peer progress
    reg [2:0] a_peer_progress_sync_rrr [0:SYNC_STAGES];

    // A-side sync of B-side sequence complete
    reg       b_seq_complete_sync_rrr [0:SYNC_STAGES];
    // B-side sync of A-side sequence complete
    reg       a_seq_complete_sync_rrr [0:SYNC_STAGES];

    // A-side sync of B-side isolate ack
    reg       b_isolate_ack_sync_rrrr [0:SYNC_STAGES];
    // B-side sync of A-side isolate ack
    reg       a_isolate_ack_sync_rrrr [0:SYNC_STAGES];

    // A-side sync of B-side clear ack
    reg       b_clear_ack_sync_rrrr [0:SYNC_STAGES];
    // B-side sync of A-side clear ack
    reg       a_clear_ack_sync_rrrr [0:SYNC_STAGES];

    // A-side sync of B-side isolate output
    reg       b_isolate_out_sync_rrr [0:SYNC_STAGES];
    // B-side sync of A-side isolate output
    reg       a_isolate_out_sync_rrr [0:SYNC_STAGES];

    // A-side sync of B-side clear output
    reg       b_clear_out_sync_rrr [0:SYNC_STAGES];
    // B-side sync of A-side clear output
    reg       a_clear_out_sync_rrr [0:SYNC_STAGES];

    // A-side sync of B-side state
    reg [2:0] b_state_sync_rrrr [0:SYNC_STAGES];
    // B-side sync of A-side state
    reg [2:0] a_state_sync_rrrr [0:SYNC_STAGES];

    // A-side sync of B-side clear request
    reg       b_clear_req_sync_rrrr [0:SYNC_STAGES];
    // B-side sync of A-side clear request
    reg       a_clear_req_sync_rrrr [0:SYNC_STAGES];

    // A-side sync of B-side release status
    reg       b_release_status_sync_rrr [0:SYNC_STAGES];
    // B-side sync of A-side release status
    reg       a_release_status_sync_rrr [0:SYNC_STAGES];

    // A-side sync of B-side done status
    reg       b_done_status_sync_rrr [0:SYNC_STAGES];
    // B-side sync of A-side done status
    reg       a_done_status_sync_rrr [0:SYNC_STAGES];

    // A-side sync of B-side isolate status
    reg       b_isolate_status_sync_rrrr [0:SYNC_STAGES];
    // B-side sync of A-side isolate status
    reg       a_isolate_status_sync_rrrr [0:SYNC_STAGES];

    // A-side sync of B-side clear status
    reg       b_clear_status_sync_rrrr [0:SYNC_STAGES];
    // B-side sync of A-side clear status
    reg       a_clear_status_sync_rrrr [0:SYNC_STAGES];

    // A-side sync of B-side idle status
    reg       b_idle_status_sync_rrr [0:SYNC_STAGES];
    // B-side sync of A-side idle status
    reg       a_idle_status_sync_rrr [0:SYNC_STAGES];

    // A-side sync of B-side active status
    reg       b_active_status_sync_rrr [0:SYNC_STAGES];
    // B-side sync of A-side active status
    reg       a_active_status_sync_rrr [0:SYNC_STAGES];

    // A-side sync of B-side released status
    reg       b_released_status_sync_rrr [0:SYNC_STAGES];
    // B-side sync of A-side released status
    reg       a_released_status_sync_rrr [0:SYNC_STAGES];

    // A-side sync of B-side peer progress
    reg [2:0] b_peer_progress_sync_rrrr [0:SYNC_STAGES];
    // B-side sync of A-side peer progress
    reg [2:0] a_peer_progress_sync_rrrr [0:SYNC_STAGES];

    // A-side sync of B-side sequence complete
    reg       b_seq_complete_sync_rrrr [0:SYNC_STAGES];
    // B-side sync of A-side sequence complete
    reg       a_seq_complete_sync_rrrr [0:SYNC_STAGES];

    // A-side sync of B-side isolate ack
    reg       b_isolate_ack_sync_rrrrr [0:SYNC_STAGES];
    // B-side sync of A-side isolate ack
    reg       a_isolate_ack_sync_rrrrr [0:SYNC_STAGES];

    // A-side sync of B-side clear ack
    reg       b_clear_ack_sync_rrrrr [0:SYNC_STAGES];
    // B-side sync of A-side clear ack
    reg       a_clear_ack_sync_rrrrr [0:SYNC_STAGES];

    // A-side sync of B-side isolate output
    reg       b_isolate_out_sync_rrrr [0:SYNC_STAGES];
    // B-side sync of A-side isolate output
    reg       a_isolate_out_sync_rrrr [0:SYNC_STAGES];

    // A-side sync of B-side clear output
    reg       b_clear_out_sync_rrrr [0:SYNC_STAGES];
    // B-side sync of A-side clear output
    reg       a_clear_out_sync_rrrr [0:SYNC_STAGES];

    // A-side sync of B-side state
    reg [2:0] b_state_sync_rrrrr [0:SYNC_STAGES];
    // B-side sync of A-side state
    reg [2:0] a_state_sync_rrrrr [0:SYNC_STAGES];

    // A-side sync of B-side clear request
    reg       b_clear_req_sync_rrrrr [0:SYNC_STAGES];
    // B-side sync of A-side clear request
    reg       a_clear_req_sync_rrrrr [0:SYNC_STAGES];

    // A-side sync of B-side release status
    reg       b_release_status_sync_rrrr [0:SYNC_STAGES];
    // B-side sync of A-side release status
    reg       a_release_status_sync_rrrr [0:SYNC_STAGES];

    // A-side sync of B-side done status
    reg       b_done_status_sync_rrrr [0:SYNC_STAGES];
    // B-side sync of A-side done status
    reg       a_done_status_sync_rrrr [0:SYNC_STAGES];

    // A-side sync of B-side isolate status
    reg       b_isolate_status_sync_rrrrr [0:SYNC_STAGES];
    // B-side sync of A-side isolate status
    reg       a_isolate_status_sync_rrrrr [0:SYNC_STAGES];

    // A-side sync of B-side clear status
    reg       b_clear_status_sync_rrrrr [0:SYNC_STAGES];
    // B-side sync of A-side clear status
    reg       a_clear_status_sync_rrrrr [0:SYNC_STAGES];

    // A-side sync of B-side idle status
    reg       b_idle_status_sync_rrrr [0:SYNC_STAGES];
    // B-side sync of A-side idle status
    reg       a_idle_status_sync_rrrr [0:SYNC_STAGES];

    // A-side sync of B-side active status
    reg       b_active_status_sync_rrrr [0:SYNC_STAGES];
    // B-side sync of A-side active status
    reg       a_active_status_sync_rrrr [0:SYNC_STAGES];

    // A-side sync of B-side released status
    reg       b_released_status_sync_rrrr [0:SYNC_STAGES];
    // B-side sync of A-side released status
    reg       a_released_status_sync_rrrr [0:SYNC_STAGES];

    // A-side sync of B-side peer progress
    reg [2:0] b_peer_progress_sync_rrrrr [0:SYNC_STAGES];
    // B-side sync of A-side peer progress
    reg [2:0] a_peer_progress_sync_rrrrr [0:SYNC_STAGES];

    // A-side sync of B-side sequence complete
    reg       b_seq_complete_sync_rrrrr [0:SYNC_STAGES];
    // B-side sync of A-side sequence complete
    reg       a_seq_complete_sync_rrrrr [0:SYNC_STAGES];

    // A-side sync of B-side isolate ack
    reg       b_isolate_ack_sync_rrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side isolate ack
    reg       a_isolate_ack_sync_rrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side clear ack
    reg       b_clear_ack_sync_rrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side clear ack
    reg       a_clear_ack_sync_rrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side isolate output
    reg       b_isolate_out_sync_rrrrr [0:SYNC_STAGES];
    // B-side sync of A-side isolate output
    reg       a_isolate_out_sync_rrrrr [0:SYNC_STAGES];

    // A-side sync of B-side clear output
    reg       b_clear_out_sync_rrrrr [0:SYNC_STAGES];
    // B-side sync of A-side clear output
    reg       a_clear_out_sync_rrrrr [0:SYNC_STAGES];

    // A-side sync of B-side state
    reg [2:0] b_state_sync_rrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side state
    reg [2:0] a_state_sync_rrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side clear request
    reg       b_clear_req_sync_rrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side clear request
    reg       a_clear_req_sync_rrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side release status
    reg       b_release_status_sync_rrrrr [0:SYNC_STAGES];
    // B-side sync of A-side release status
    reg       a_release_status_sync_rrrrr [0:SYNC_STAGES];

    // A-side sync of B-side done status
    reg       b_done_status_sync_rrrrr [0:SYNC_STAGES];
    // B-side sync of A-side done status
    reg       a_done_status_sync_rrrrr [0:SYNC_STAGES];

    // A-side sync of B-side isolate status
    reg       b_isolate_status_sync_rrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side isolate status
    reg       a_isolate_status_sync_rrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side clear status
    reg       b_clear_status_sync_rrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side clear status
    reg       a_clear_status_sync_rrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side idle status
    reg       b_idle_status_sync_rrrrr [0:SYNC_STAGES];
    // B-side sync of A-side idle status
    reg       a_idle_status_sync_rrrrr [0:SYNC_STAGES];

    // A-side sync of B-side active status
    reg       b_active_status_sync_rrrrr [0:SYNC_STAGES];
    // B-side sync of A-side active status
    reg       a_active_status_sync_rrrrr [0:SYNC_STAGES];

    // A-side sync of B-side released status
    reg       b_released_status_sync_rrrrr [0:SYNC_STAGES];
    // B-side sync of A-side released status
    reg       a_released_status_sync_rrrrr [0:SYNC_STAGES];

    // A-side sync of B-side peer progress
    reg [2:0] b_peer_progress_sync_rrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side peer progress
    reg [2:0] a_peer_progress_sync_rrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side sequence complete
    reg       b_seq_complete_sync_rrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side sequence complete
    reg       a_seq_complete_sync_rrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side isolate ack
    reg       b_isolate_ack_sync_rrrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side isolate ack
    reg       a_isolate_ack_sync_rrrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side clear ack
    reg       b_clear_ack_sync_rrrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side clear ack
    reg       a_clear_ack_sync_rrrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side isolate output
    reg       b_isolate_out_sync_rrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side isolate output
    reg       a_isolate_out_sync_rrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side clear output
    reg       b_clear_out_sync_rrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side clear output
    reg       a_clear_out_sync_rrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side state
    reg [2:0] b_state_sync_rrrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side state
    reg [2:0] a_state_sync_rrrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side clear request
    reg       b_clear_req_sync_rrrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side clear request
    reg       a_clear_req_sync_rrrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side release status
    reg       b_release_status_sync_rrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side release status
    reg       a_release_status_sync_rrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side done status
    reg       b_done_status_sync_rrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side done status
    reg       a_done_status_sync_rrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side isolate status
    reg       b_isolate_status_sync_rrrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side isolate status
    reg       a_isolate_status_sync_rrrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side clear status
    reg       b_clear_status_sync_rrrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side clear status
    reg       a_clear_status_sync_rrrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side idle status
    reg       b_idle_status_sync_rrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side idle status
    reg       a_idle_status_sync_rrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side active status
    reg       b_active_status_sync_rrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side active status
    reg       a_active_status_sync_rrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side released status
    reg       b_released_status_sync_rrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side released status
    reg       a_released_status_sync_rrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side peer progress
    reg [2:0] b_peer_progress_sync_rrrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side peer progress
    reg [2:0] a_peer_progress_sync_rrrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side sequence complete
    reg       b_seq_complete_sync_rrrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side sequence complete
    reg       a_seq_complete_sync_rrrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side isolate ack
    reg       b_isolate_ack_sync_rrrrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side isolate ack
    reg       a_isolate_ack_sync_rrrrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side clear ack
    reg       b_clear_ack_sync_rrrrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side clear ack
    reg       a_clear_ack_sync_rrrrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side isolate output
    reg       b_isolate_out_sync_rrrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side isolate output
    reg       a_isolate_out_sync_rrrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side clear output
    reg       b_clear_out_sync_rrrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side clear output
    reg       a_clear_out_sync_rrrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side state
    reg [2:0] b_state_sync_rrrrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side state
    reg [2:0] a_state_sync_rrrrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side clear request
    reg       b_clear_req_sync_rrrrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side clear request
    reg       a_clear_req_sync_rrrrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side release status
    reg       b_release_status_sync_rrrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side release status
    reg       a_release_status_sync_rrrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side done status
    reg       b_done_status_sync_rrrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side done status
    reg       a_done_status_sync_rrrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side isolate status
    reg       b_isolate_status_sync_rrrrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side isolate status
    reg       a_isolate_status_sync_rrrrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side clear status
    reg       b_clear_status_sync_rrrrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side clear status
    reg       a_clear_status_sync_rrrrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side idle status
    reg       b_idle_status_sync_rrrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side idle status
    reg       a_idle_status_sync_rrrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side active status
    reg       b_active_status_sync_rrrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side active status
    reg       a_active_status_sync_rrrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side released status
    reg       b_released_status_sync_rrrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side released status
    reg       a_released_status_sync_rrrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side peer progress
    reg [2:0] b_peer_progress_sync_rrrrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side peer progress
    reg [2:0] a_peer_progress_sync_rrrrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side sequence complete
    reg       b_seq_complete_sync_rrrrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side sequence complete
    reg       a_seq_complete_sync_rrrrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side isolate ack
    reg       b_isolate_ack_sync_rrrrrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side isolate ack
    reg       a_isolate_ack_sync_rrrrrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side clear ack
    reg       b_clear_ack_sync_rrrrrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side clear ack
    reg       a_clear_ack_sync_rrrrrrrrr [0:SYNC_STAGES];

    // A-side sync of B-side isolate output
    reg       b_isolate_out_sync_rrrrrrrr [0:SYNC_STAGES];
    // B-side sync of A-side isolate output
    reg       a_isolate