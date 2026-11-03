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
    localparam S_WAIT_DONE = 3'd4;

    // A-side state
    reg [2:0] a_state;
    reg       a_isolate_o_r;
    reg       a_clear_o_r;

    // B-side state
    reg [2:0] b_state;
    reg       b_isolate_o_r;
    reg       b_clear_o_r;

    // A-side sync of B-side status (2 bits: isolate, clear)
    reg [1:0] b_status_a_sync;
    reg [1:0] b_status_a_sync_next;

    // B-side sync of A-side status (2 bits: isolate, clear)
    reg [1:0] a_status_b_sync;
    reg [1:0] a_status_b_sync_next;

    // A-side sync of B-side clear request
    reg       b_clear_a_sync;
    reg       b_clear_a_sync_next;

    // B-side sync of A-side clear request
    reg       a_clear_b_sync;
    reg       a_clear_b_sync_next;

    // A-side sync of B-side isolate ack
    reg       b_isolate_ack_a_sync;
    reg       b_isolate_ack_a_sync_next;

    // B-side sync of A-side isolate ack
    reg       a_isolate_ack_b_sync;
    reg       a_isolate_ack_b_sync_next;

    // A-side sync of B-side clear ack
    reg       b_clear_ack_a_sync;
    reg       b_clear_ack_a_sync_next;

    // B-side sync of A-side clear ack
    reg       a_clear_ack_b_sync;
    reg       a_clear_ack_b_sync_next;

    // A-side sync of B-side release status
    reg       b_release_a_sync;
    reg       b_release_a_sync_next;

    // B-side sync of A-side release status
    reg       a_release_b_sync;
    reg       a_release_b_sync_next;

    // A-side sync of B-side done status
    reg       b_done_a_sync;
    reg       b_done_a_sync_next;

    // B-side sync of A-side done status
    reg       a_done_b_sync;
    reg       a_done_b_sync_next;

    // A-side sync of B-side idle status
    reg       b_idle_a_sync;
    reg       b_idle_a_sync_next;

    // B-side sync of A-side idle status
    reg       a_idle_b_sync;
    reg       a_idle_b_sync_next;

    // A-side sync of B-side active status
    reg       b_active_a_sync;
    reg       b_active_a_sync_next;

    // B-side sync of A-side active status
    reg       a_active_b_sync;
    reg       a_active_b_sync_next;

    // A-side sync of B-side released status
    reg       b_released_a_sync;
    reg       b_released_a_sync_next;

    // B-side sync of A-side released status
    reg       a_released_b_sync;
    reg       a_released_b_sync_next;

    // A-side sync of B-side wait_done status
    reg       b_wait_done_a_sync;
    reg       b_wait_done_a_sync_next;

    // B-side sync of A-side wait_done status
    reg       a_wait_done_b_sync;
    reg       a_wait_done_b_sync_next;

    // A-side sync of B-side isolate status
    reg       b_isolate_a_sync;
    reg       b_isolate_a_sync_next;

    // B-side sync of A-side isolate status
    reg       a_isolate_b_sync;
    reg       a_isolate_b_sync_next;

    // A-side sync of B-side clear status
    reg       b_clear_a_sync;
    reg       b_clear_a_sync_next;

    // B-side sync of A-side clear status
    reg       a_clear_b_sync;
    reg       a_clear_b_sync_next;

    // A-side sync of B-side release status
    reg       b_release_a_sync;
    reg       b_release_a_sync_next;

    // B-side sync of A-side release status
    reg       a_release_b_sync;
    reg       a_release_b_sync_next;

    // A-side sync of B-side done status
    reg       b_done_a_sync;
    reg       b_done_a_sync_next;

    // B-side sync of A-side done status
    reg       a_done_b_sync;
    reg       a_done_b_sync_next;

    // A-side sync of B-side idle status
    reg       b_idle_a_sync;
    reg       b_idle_a_sync_next;

    // B-side sync of A-side idle status
    reg       a_idle_b_sync;
    reg       a_idle_b_sync_next;

    // A-side sync of B-side active status
    reg       b_active_a_sync;
    reg       b_active_a_sync_next;

    // B-side sync of A-side active status
    reg       a_active_b_sync;
    reg       a_active_b_sync_next;

    // A-side sync of B-side released status
    reg       b_released_a_sync;
    reg       b_released_a_sync_next;

    // B-side sync of A-side released status
    reg       a_released_b_sync;
    reg       a_released_b_sync_next;

    // A-side sync of B-side wait_done status
    reg       b_wait_done_a_sync;
    reg       b_wait_done_a_sync_next;

    // B-side sync of A-side wait_done status
    reg       a_wait_done_b_sync;
    reg       a_wait_done_b_sync_next;

    // A-side sync of B-side isolate status
    reg       b_isolate_a_sync;
    reg       b_isolate_a_sync_next;

    // B-side sync of A-side isolate status
    reg       a_isolate_b_sync;
    reg       a_isolate_b_sync_next;

    // A-side sync of B-side clear status
    reg       b_clear_a_sync;
    reg       b_clear_a_sync_next;

    // B-side sync of A-side clear status
    reg       a_clear_b_sync;
    reg       a_clear_b_sync_next;

    // A-side sync of B-side release status
    reg       b_release_a_sync;
    reg       b_release_a_sync_next;

    // B-side sync of A-side release status
    reg       a_release_b_sync;
    reg       a_release_b_sync_next;

    // A-side sync of B-side done status
    reg       b_done_a_sync;
    reg       b_done_a_sync_next;

    // B-side sync of A-side done status
    reg       a_done_b_sync;
    reg       a_done_b_sync_next;

    // A-side sync of B-side idle status
    reg       b_idle_a_sync;
    reg       b_idle_a_sync_next;

    // B-side sync of A-side idle status
    reg       a_idle_b_sync;
    reg       a_idle_b_sync_next;

    // A-side sync of B-side active status
    reg       b_active_a_sync;
    reg       b_active_a_sync_next;

    // B-side sync of A-side active status
    reg       a_active_b_sync;
    reg       a_active_b_sync_next;

    // A-side sync of B-side released status
    reg       b_released_a_sync;
    reg       b_released_a_sync_next;

    // B-side sync of A-side released status
    reg       a_released_b_sync;
    reg       a_released_b_sync_next;

    // A-side sync of B-side wait_done status
    reg       b_wait_done_a_sync;
    reg       b_wait_done_a_sync_next;

    // B-side sync of A-side wait_done status
    reg       a_wait_done_b_sync;
    reg       a_wait_done_b_sync_next;

    // A-side sync of B-side isolate status
    reg       b_isolate_a_sync;
    reg       b_isolate_a_sync_next;

    // B-side sync of A-side isolate status
    reg       a_isolate_b_sync;
    reg       a_isolate_b_sync_next;

    // A-side sync of B-side clear status
    reg       b_clear_a_sync;
    reg       b_clear_a_sync_next;

    // B-side sync of A-side clear status
    reg       a_clear_b_sync;
    reg       a_clear_b_sync_next;

    // A-side sync of B-side release status
    reg       b_release_a_sync;
    reg       b_release_a_sync_next;

    // B-side sync of A-side release status
    reg       a_release_b_sync;
    reg       a_release_b_sync_next;

    // A-side sync of B-side done status
    reg       b_done_a_sync;
    reg       b_done_a_sync_next;

    // B-side sync of A-side done status
    reg       a_done_b_sync;
    reg       a_done_b_sync_next;

    // A-side sync of B-side idle status
    reg       b_idle_a_sync;
    reg       b_idle_a_sync_next;

    // B-side sync of A-side idle status
    reg       a_idle_b_sync;
    reg       a_idle_b_sync_next;

    // A-side sync of B-side active status
    reg       b_active_a_sync;
    reg       b_active_a_sync_next;

    // B-side sync of A-side active status
    reg       a_active_b_sync;
    reg       a_active_b_sync_next;

    // A-side sync of B-side released status
    reg       b_released_a_sync;
    reg       b_released_a_sync_next;

    // B-side sync of A-side released status
    reg       a_released_b_sync;
    reg       a_released_b_sync_next;

    // A-side sync of B-side wait_done status
    reg       b_wait_done_a_sync;
    reg       b_wait_done_a_sync_next;

    // B-side sync of A-side wait_done status
    reg       a_wait_done_b_sync;
    reg       a_wait_done_b_sync_next;

    // A-side sync of B-side isolate status
    reg       b_isolate_a_sync;
    reg       b_isolate_a_sync_next;

    // B-side sync of A-side isolate status
    reg       a_isolate_b_sync;
    reg       a_isolate_b_sync_next;

    // A-side sync of B-side clear status
    reg       b_clear_a_sync;
    reg       b_clear_a_sync_next;

    // B-side sync of A-side clear status
    reg       a_clear_b_sync;
    reg       a_clear_b_sync_next;

    // A-side sync of B-side release status
    reg       b_release_a_sync;
    reg       b_release_a_sync_next;

    // B-side sync of A-side release status
    reg       a_release_b_sync;
    reg       a_release_b_sync_next;

    // A-side sync of B-side done status
    reg       b_done_a_sync;
    reg       b_done_a_sync_next;

    // B-side sync of A-side done status
    reg       a_done_b_sync;
    reg       a_done_b_sync_next;

    // A-side sync of B-side idle status
    reg       b_idle_a_sync;
    reg       b_idle_a_sync_next;

    // B-side sync of A-side idle status
    reg       a_idle_b_sync;
    reg       a_idle_b_sync_next;

    // A-side sync of B-side active status
    reg       b_active_a_sync;
    reg       b_active_a_sync_next;

    // B-side sync of A-side active status
    reg       a_active_b_sync;
    reg       a_active_b_sync_next;

    // A-side sync of B-side released status
    reg       b_released_a_sync;
    reg       b_released_a_sync_next;

    // B-side sync of A-side released status
    reg       a_released_b_sync;
    reg       a_released_b_sync_next;

    // A-side sync of B-side wait_done status
    reg       b_wait_done_a_sync;
    reg       b_wait_done_a_sync_next;

    // B-side sync of A-side wait_done status
    reg       a_wait_done_b_sync;
    reg       a_wait_done_b_sync_next;

    // A-side sync of B-side isolate status
    reg       b_isolate_a_sync;
    reg       b_isolate_a_sync_next;

    // B-side sync of A-side isolate status
    reg       a_isolate_b_sync;
    reg       a_isolate_b_sync_next;

    // A-side sync of B-side clear status
    reg       b_clear_a_sync;
    reg       b_clear_a_sync_next;

    // B-side sync of A-side clear status
    reg       a_clear_b_sync;
    reg       a_clear_b_sync_next;

    // A-side sync of B-side release status
    reg       b_release_a_sync;
    reg       b_release_a_sync_next;

    // B-side sync of A-side release status
    reg       a_release_b_sync;
    reg       a_release_b_sync_next;

    // A-side sync of B-side done status
    reg       b_done_a_sync;
    reg       b_done_a_sync_next;

    // B-side sync of A-side done status
    reg       a_done_b_sync;
    reg       a_done_b_sync_next;

    // A-side sync of B-side idle status
    reg       b_idle_a_sync;
    reg       b_idle_a_sync_next;

    // B-side sync of A-side idle status
    reg       a_idle_b_sync;
    reg       a_idle_b_sync_next;

    // A-side sync of B-side active status
    reg       b_active_a_sync;
    reg       b_active_a_sync_next;

    // B-side sync of A-side active status
    reg       a_active_b_sync;
    reg       a_active_b_sync_next;

    // A-side sync of B-side released status
    reg       b_released_a_sync;
    reg       b_released_a_sync_next;

    // B-side sync of A-side released status
    reg       a_released_b_sync;
    reg       a_released_b_sync_next;

    // A-side sync of B-side wait_done status
    reg       b_wait_done_a_sync;
    reg       b_wait_done_a_sync_next;

    // B-side sync of A-side wait_done status
    reg       a_wait_done_b_sync;
    reg       a_wait_done_b_sync_next;

    // A-side sync of B-side isolate status
    reg       b_isolate_a_sync;
    reg       b_isolate_a_sync_next;

    // B-side sync of A-side isolate status
    reg       a_isolate_b_sync;
    reg       a_isolate_b_sync_next;

    // A-side sync of B-side clear status
    reg       b_clear_a_sync;
    reg       b_clear_a_sync_next;

    // B-side sync of A-side clear status
    reg       a_clear_b_sync;
    reg       a_clear_b_sync_next;

    // A-side sync of B-side release status
    reg       b_release_a_sync;
    reg       b_release_a_sync_next;

    // B-side sync of A-side release status
    reg       a_release_b_sync;
    reg       a_release_b_sync_next;

    // A-side sync of B-side done status
    reg       b_done_a_sync;
    reg       b_done_a_sync_next;

    // B-side sync of A-side done status
    reg       a_done_b_sync;
    reg       a_done_b_sync_next;

    // A-side sync of B-side idle status
    reg       b_idle_a_sync;
    reg       b_idle_a_sync_next;

    // B-side sync of A-side idle status
    reg       a_idle_b_sync;
    reg       a_idle_b_sync_next;

    // A-side sync of B-side active status
    reg       b_active_a_sync;
    reg       b_active_a_sync_next;

    // B-side sync of A-side active status
    reg       a_active_b_sync;
    reg       a_active_b_sync_next;

    // A-side sync of B-side released status
    reg       b_released_a_sync;
    reg       b_released_a_sync_next;

    // B-side sync of A-side released status
    reg       a_released_b_sync;
    reg       a_released_b_sync_next;

    // A-side sync of B-side wait_done status
    reg       b_wait_done_a_sync;
    reg       b_wait_done_a_sync_next;

    // B-side sync of A-side wait_done status
    reg       a_wait_done_b_sync;
    reg       a_wait_done_b_sync_next;

    // A-side sync of B-side isolate status
    reg       b_isolate_a_sync;
    reg       b_isolate_a_sync_next;

    // B-side sync of A-side isolate status
    reg       a_isolate_b_sync;
    reg       a_isolate_b_sync_next;

    // A-side sync of B-side clear status
    reg       b_clear_a_sync;
    reg       b_clear_a_sync_next;

    // B-side sync of A-side clear status
    reg       a_clear_b_sync;
    reg       a_clear_b_sync_next;

    // A-side sync of B-side release status
    reg       b_release_a_sync;
    reg       b_release_a_sync_next;

    // B-side sync of A-side release status
    reg       a_release_b_sync;
    reg       a_release_b_sync_next;

    // A-side sync of B-side done status
    reg       b_done_a_sync;
    reg       b_done_a_sync_next;

    // B-side sync of A-side done status
    reg       a_done_b_sync;
    reg       a_done_b_sync_next;

    // A-side sync of B-side idle status
    reg       b_idle_a_sync;
    reg       b_idle_a_sync_next;

    // B-side sync of A-side idle status
    reg       a_idle_b_sync;
    reg       a_idle_b_sync_next;

    // A-side sync of B-side active status
    reg       b_active_a_sync;
    reg       b_active_a_sync_next;

    // B-side sync of A-side active status
    reg       a_active_b_sync;
    reg       a_active_b_sync_next;

    // A-side sync of B-side released status
    reg       b_released_a_sync;
    reg       b_released_a_sync_next;

    // B-side sync of A-side released status
    reg       a_released_b_sync;
    reg       a_released_b_sync_next;

    // A-side sync of B-side wait_done status
    reg       b_wait_done_a_sync;
    reg       b_wait_done_a_sync_next;

    // B-side sync of A-side wait_done status
    reg       a_wait_done_b_sync;
    reg       a_wait_done_b_sync_next;

    // A-side sync of B-side isolate status
    reg       b_isolate_a_sync;
    reg       b_isolate_a_sync_next;

    // B-side sync of A-side isolate status
    reg       a_isolate_b_sync;
    reg       a_isolate_b_sync_next;

    // A-side sync of B-side clear status
    reg       b_clear_a_sync;
    reg       b_clear_a_sync_next;

    // B-side sync of A-side clear status
    reg       a_clear_b_sync;
    reg       a_clear_b_sync_next;

    // A-side sync of B-side release status
    reg       b_release_a_sync;
    reg       b_release_a_sync_next;

    // B-side sync of A-side release status
    reg       a_release_b_sync;
    reg       a_release_b_sync_next;

    // A-side sync of B-side done status
    reg       b_done_a_sync;
    reg       b_done_a_sync_next;

    // B-side sync of A-side done status
    reg       a_done_b_sync;
    reg       a_done_b_sync_next;

    // A-side sync of B-side idle status
    reg       b_idle_a_sync;
    reg       b_idle_a_sync_next;

    // B-side sync of A-side idle status
    reg       a_idle_b_sync;
    reg       a_idle_b_sync_next;

    // A-side sync of B-side active status
    reg       b_active_a_sync;
    reg       b_active_a_sync_next;

    // B-side sync of A-side active status
    reg       a_active_b_sync;
    reg       a_active_b_sync_next;

    // A-side sync of B-side released status
    reg       b_released_a_sync;
    reg       b_released_a_sync_next;

    // B-side sync of A-side released status
    reg       a_released_b_sync;
    reg       a_released_b_sync_next;

    // A-side sync of B-side wait_done status
    reg       b_wait_done_a_sync;
    reg       b_wait_done_a_sync_next;

    // B-side sync of A-side wait_done status
    reg       a_wait_done_b_sync;
    reg       a_wait_done_b_sync_next;

    // A-side sync of B-side isolate status
    reg       b_isolate_a_sync;
    reg       b_isolate_a_sync_next;

    // B-side sync of A-side isolate status
    reg       a_isolate_b_sync;
    reg       a_isolate_b_sync_next;

    // A-side sync of B-side clear status
    reg       b_clear_a_sync;
    reg       b_clear_a_sync_next;

    // B-side sync of A-side clear status
    reg       a_clear_b_sync;
    reg       a_clear_b_sync_next;

    // A-side sync of B-side release status
    reg       b_release_a_sync;
    reg       b_release_a_sync_next;

    // B-side sync of A-side release status
    reg       a_release_b_sync;
    reg       a_release_b_sync_next;

    // A-side sync of B-side done status
    reg       b_done_a_sync;
    reg       b_done_a_sync_next;

    // B-side sync of A-side done status
    reg       a_done_b_sync;
    reg       a_done_b_sync_next;

    // A-side sync of B-side idle status
    reg       b_idle_a_sync;
    reg       b_idle_a_sync_next;

    // B-side sync of A-side idle status
    reg       a_idle_b_sync;
    reg       a_idle_b_sync_next;

    // A-side sync of B-side active status
    reg       b_active_a_sync;
    reg       b_active_a_sync_next;

    // B-side sync of A-side active status
    reg       a_active_b_sync;
    reg       a_active_b_sync_next;

    // A-side sync of B-side released status
    reg       b_released_a_sync;
    reg       b_released_a_sync_next;

    // B-side sync of A-side released status
    reg       a_released_b_sync;
    reg       a_released_b_sync_next;

    // A-side sync of B-side wait_done status
    reg       b_wait_done_a_sync;
    reg       b_wait_done_a_sync_next;

    // B-side sync of A-side wait_done status
    reg       a_wait_done_b_sync;
    reg       a_wait_done_b_sync_next;

    // A-side sync of B-side isolate status
    reg       b_isolate_a_sync;
    reg       b_isolate_a_sync_next;

    // B-side sync of A-side isolate status
    reg       a_isolate_b_sync;
    reg       a_isolate_b_sync_next;

    // A-side sync of B-side clear status
    reg       b_clear_a_sync;
    reg       b_clear_a_sync_next;

    // B-side sync of A-side clear status
    reg       a_clear_b_sync;
    reg       a_clear_b_sync_next;

    // A-side sync of B-side release status
    reg       b_release_a_sync;
    reg       b_release_a_sync_next;

    // B-side sync of A-side release status
    reg       a_release_b_sync;
    reg       a_release_b_sync_next;

    // A-side sync of B-side done status
    reg       b_done_a_sync;
    reg       b_done_a_sync_next;

    // B-side sync of A-side done status
    reg       a_done_b_sync;
    reg       a_done_b_sync_next;

    // A-side sync of B-side idle status
    reg       b_idle_a_sync;
    reg       b_idle_a_sync_next;

    // B-side sync of A-side idle status
    reg       a_idle_b_sync;
    reg       a_idle_b_sync_next;

    // A-side sync of B-side active status
    reg       b_active_a_sync;
    reg       b_active_a_sync_next;

    // B-side sync of A-side active status
    reg       a_active_b_sync;
    reg       a_active_b_sync_next;

    // A-side sync of B-side released status
    reg       b_released_a_sync;
    reg       b_released_a_sync_next;

    // B-side sync of A-side released status
    reg       a_released_b_sync;
    reg       a_released_b_sync_next;

    // A-side sync of B-side wait_done status
    reg       b_wait_done_a_sync;
    reg       b_wait_done_a_sync_next;

    // B-side sync of A-side wait_done status
    reg       a_wait_done_b_sync;
    reg       a_wait_done_b_sync_next;

    // A-side sync of B-side isolate status
    reg       b_isolate_a_sync;
    reg       b_isolate_a_sync_next;

    // B-side sync of A-side isolate status
    reg       a_isolate_b_sync;
    reg       a_isolate_b_sync_next;

    // A-side sync of B-side clear status
    reg       b_clear_a_sync;
    reg       b_clear_a_sync_next;

    // B-side sync of A-side clear status
    reg       a_clear_b_sync;
    reg       a_clear_b_sync_next;

    // A-side sync of B-side release status
    reg       b_release_a_sync;
    reg       b_release_a_sync_next;

    // B-side sync of A-side release status
    reg       a_release_b_sync;
    reg       a_release_b_sync_next;

    // A-side sync of B-side done status
    reg       b_done_a_sync;
    reg       b_done_a_sync_next;

    // B-side sync of A-side done status
    reg       a_done_b_sync;
    reg       a_done_b_sync_next;

    // A-side sync of B-side idle status
    reg       b_idle_a_sync;
    reg       b_idle_a_sync_next;

    // B-side sync of A-side idle status
    reg       a_idle_b_sync;
    reg       a_idle_b_sync_next;

    // A-side sync of B-side active status
    reg       b_active_a_sync;
    reg       b_active_a_sync_next;

    // B-side sync of A-side active status
    reg       a_active_b_sync;
    reg       a_active_b_sync_next;

    // A-side sync of B-side released status
    reg       b_released_a_sync;
    reg       b_released_a_sync_next;

    // B-side sync of A-side released status
    reg       a_released_b_sync;
    reg       a_released_b_sync_next;

    // A-side sync of B-side wait_done status
    reg       b_wait_done_a_sync;
    reg       b_wait_done_a_sync_next;

    // B-side sync of A-side wait_done status
    reg       a_wait_done_b_sync;
    reg       a_wait_done_b_sync_next;

    // A-side sync of B-side isolate status
    reg       b_isolate_a_sync;
    reg       b_isolate_a_sync_next;

    // B-side sync of A-side isolate status
    reg       a_isolate_b_sync;
    reg       a_isolate_b_sync_next;

    // A-side sync of B-side clear status
    reg       b_clear_a_sync;
    reg       b_clear_a_sync_next;

    // B-side sync of A-side clear status
    reg       a_clear_b_sync;
    reg       a_clear_b_sync_next;

    // A-side sync of B-side release status
    reg       b_release_a_sync;
    reg       b_release_a_sync_next;

    // B-side sync of A-side release status
    reg       a_release_b_sync;
    reg       a_release_b_sync_next;

    // A-side sync of B-side done status
    reg       b_done_a_sync;
    reg       b_done_a_sync_next;

    // B-side sync of A-side done status
    reg       a_done_b_sync;
    reg       a_done_b_sync_next;

    // A-side sync of B-side idle status
    reg       b_idle_a_sync;
    reg       b_idle_a_sync_next;

    // B-side sync of A-side idle status
    reg       a_idle_b_sync;
    reg       a_idle_b_sync_next;

    // A-side sync of B-side active status
    reg       b_active_a_sync;
    reg       b_active_a_sync_next;

    // B-side sync of A-side active status
    reg       a_active_b_sync;
    reg       a_active_b_sync_next;

    // A-side sync of B-side released status
    reg       b_released_a_sync;
    reg       b_released_a_sync_next;

    // B-side sync of A-side released status
    reg       a_released_b_sync;
    reg       a_released_b_sync_next;

    // A-side sync of B-side wait_done status
    reg       b_wait_done_a_sync;
    reg       b_wait_done_a_sync_next;

    // B-side sync of A-side wait_done status
    reg       a_wait_done_b_sync;
    reg       a_wait_done_b_sync_next;

    // A-side sync of B-side isolate status
    reg       b_isolate_a_sync;
    reg       b_isolate_a_sync_next;

    // B-side sync of A-side isolate status
    reg       a_isolate_b_sync;
    reg       a_isolate_b_sync_next;

    // A-side sync of B-side clear status
    reg       b_clear_a_sync;
    reg       b_clear_a_sync_next;

    // B-side sync of A-side clear status
    reg       a_clear_b_sync;
    reg       a_clear_b_sync_next;

    // A-side sync of B-side release status
    reg       b_release_a_sync;
    reg       b_release_a_sync_next;

    // B-side sync of A-side release status
    reg       a_release_b_sync;
    reg       a_release_b_sync_next;

    // A-side sync of B-side done status
    reg       b_done_a_sync;
    reg       b_done_a_sync_next;

    // B-side sync of A-side done status
    reg       a_done_b_sync;
    reg       a_done_b_sync_next;

    // A-side sync of B-side idle status
    reg       b_idle_a_sync;
    reg       b_idle_a_sync_next;

    // B-side sync of A-side idle status
    reg       a_idle_b_sync;
    reg       a_idle_b_sync_next;

    // A-side sync of B-side active status
    reg       b_active_a_sync;
    reg       b_active_a_sync_next;

    // B-side sync of A-side active status
    reg       a_active_b_sync;
    reg       a_active_b_sync_next;

    // A-side sync of B-side released status
    reg       b_released_a_sync;
    reg       b_released_a_sync_next;

    // B-side sync of A-side released status
    reg       a_released_b_sync;
    reg       a_released_b_sync_next;

    // A-side sync of B-side wait_done status
    reg       b_wait_done_a_sync;
    reg       b_wait_done_a_sync_next;

    // B-side sync of A-side wait_done status
    reg       a_wait_done_b_sync;
    reg       a_wait_done_b_sync_next;

    // A-side sync of B-side isolate status
    reg       b_isolate_a_sync;
    reg       b_isolate_a_sync_next;

    // B-side sync of A-side isolate status
    reg       a_isolate_b_sync;
    reg       a_isolate_b_sync_next;

    // A-side sync of B-side clear status
    reg       b_clear_a_sync;
    reg       b_clear_a_sync_next;

    // B-side sync of A-side clear status
    reg       a_clear_b_sync;
    reg       a_clear_b_sync_next;

    // A-side sync of B-side release status
    reg       b_release_a_sync;
    reg       b_release_a_sync_next;

    // B-side sync of A-side release status
    reg       a_release_b_sync;
    reg       a_release_b_sync_next;

    // A-side sync of B-side done status
    reg       b_done_a_sync;
    reg       b_done_a_sync_next;

    // B-side sync of A-side done status
    reg       a_done_b_sync;
    reg       a_done_b_sync_next;

    // A-side sync of B-side idle status
    reg       b_idle_a_sync;
    reg       b_idle_a_sync_next;

    // B-side sync of A-side idle status
    reg       a_idle_b_sync;
    reg       a_idle_b_sync_next;

    // A-side sync of B-side active status
    reg       b_active_a_sync;
    reg       b_active_a_sync_next;

    // B-side sync of A-side active status
    reg       a_active_b_sync;
    reg       a_active_b_sync_next;

    // A-side sync of B-side released status
    reg       b_released_a_sync;
    reg       b_released_a_sync_next;

    // B-side sync of A-side released status
    reg       a_released_b_sync;
    reg       a_released_b_sync_next;

    // A-side sync of B-side wait_done status
    reg       b_wait_done_a_sync;
    reg       b_wait_done_a_sync_next;

    // B-side sync of A-side wait_done status
    reg       a_wait_done_b_sync;
    reg       a_wait_done_b_sync_next;

    // A-side sync of B-side isolate status
    reg       b_isolate_a_sync;
    reg       b_isolate_a_sync_next;

    // B-side sync of A-side isolate status
    reg       a_isolate_b_sync;
    reg       a_isolate_b_sync_next;

    // A-side sync of B-side clear status
    reg       b_clear_a_sync;
    reg       b_clear_a_sync_next;

    // B-side sync of A-side clear status
    reg       a_clear_b_sync;
    reg       a_clear_b_sync_next;

    // A-side sync of B-side release status
    reg       b_release_a_sync;
    reg       b_release_a_sync_next;

    // B-side sync of A-side release status
    reg       a_release_b_sync;
    reg       a_release_b_sync_next;

    // A-side sync of B-side done status
    reg       b_done_a_sync;
    reg       b_done_a_sync_next;

    // B-side sync of A-side done status
    reg       a_done_b_sync;
    reg       a_done_b_sync_next;

    // A-side sync of B-side idle status
    reg       b_idle_a_sync;
    reg       b_idle_a_sync_next;

    // B-side sync of A-side idle status
    reg       a_idle_b_sync;
    reg       a_idle_b_sync_next;

    // A-side sync of B-side active status
    reg       b_active_a_sync;
    reg       b_active_a_sync_next;

    //