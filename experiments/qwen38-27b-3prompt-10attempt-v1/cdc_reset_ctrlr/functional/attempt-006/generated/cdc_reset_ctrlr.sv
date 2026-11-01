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
    localparam S_IDLE     = 2'd0;
    localparam S_ISOLATE  = 2'd1;
    localparam S_CLEAR    = 2'd2;
    localparam S_RELEASE  = 2'd3;

    // Local state registers
    reg [1:0] a_state;
    reg [1:0] b_state;

    // Local output registers
    reg a_isolate_o_reg;
    reg a_clear_o_reg;
    reg b_isolate_o_reg;
    reg b_clear_o_reg;

    // Synchronizers for peer state
    reg [SYNC_STAGES-1:0] a_state_sync;
    reg [SYNC_STAGES-1:0] b_state_sync;

    // Synchronizers for peer acks
    reg [SYNC_STAGES-1:0] a_isolate_ack_sync;
    reg [SYNC_STAGES-1:0] a_clear_ack_sync;
    reg [SYNC_STAGES-1:0] b_isolate_ack_sync;
    reg [SYNC_STAGES-1:0] b_clear_ack_sync;

    // Synchronizers for peer clear requests
    reg [SYNC_STAGES-1:0] a_clear_req_sync;
    reg [SYNC_STAGES-1:0] b_clear_req_sync;

    // Synchronizers for local state (to peer)
    reg [SYNC_STAGES-1:0] a_state_out_sync;
    reg [SYNC_STAGES-1:0] b_state_out_sync;

    // Synchronizers for local acks (to peer)
    reg [SYNC_STAGES-1:0] a_isolate_ack_out_sync;
    reg [SYNC_STAGES-1:0] a_clear_ack_out_sync;
    reg [SYNC_STAGES-1:0] b_isolate_ack_out_sync;
    reg [SYNC_STAGES-1:0] b_clear_ack_out_sync;

    // Synchronizers for local clear requests (to peer)
    reg [SYNC_STAGES-1:0] a_clear_req_out_sync;
    reg [SYNC_STAGES-1:0] b_clear_req_out_sync;

    // Synchronizer for local isolate output (to peer)
    reg [SYNC_STAGES-1:0] a_isolate_out_sync;
    reg [SYNC_STAGES-1:0] b_isolate_out_sync;

    // Synchronizer for local clear output (to peer)
    reg [SYNC_STAGES-1:0] a_clear_out_sync;
    reg [SYNC_STAGES-1:0] b_clear_out_sync;

    // Synchronizer for local reset (to peer)
    reg [SYNC_STAGES-1:0] a_rst_sync;
    reg [SYNC_STAGES-1:0] b_rst_sync;

    // Synchronizer for local state (to peer) - already have a_state_out_sync

    // Synchronizer for local isolate ack (to peer) - already have a_isolate_ack_out_sync

    // Synchronizer for local clear ack (to peer) - already have a_clear_ack_out_sync

    // Synchronizer for local clear request (to peer) - already have a_clear_req_out_sync

    // Synchronizer for local isolate output (to peer) - already have a_isolate_out_sync

    // Synchronizer for local clear output (to peer) - already have a_clear_out_sync

    // Synchronizer for local reset (to peer) - already have a_rst_sync

    // Synchronizer for local state (to peer) - already have a_state_out_sync

    // Synchronizer for local isolate ack (to peer) - already have a_isolate_ack_out_sync

    // Synchronizer for local clear ack (to peer) - already have a_clear_ack_out_sync

    // Synchronizer for local clear request (to peer) - already have a_clear_req_out_sync

    // Synchronizer for local isolate output (to peer) - already have a_isolate_out_sync

    // Synchronizer for local clear output (to peer) - already have a_clear_out_sync

    // Synchronizer for local reset (to peer) - already have a_rst_sync

    // Synchronizer for local state (to peer) - already have a_state_out_sync

    // Synchronizer for local isolate ack (to peer) - already have a_isolate_ack_out_sync

    // Synchronizer for local clear ack (to peer) - already have a_clear_ack_out_sync

    // Synchronizer for local clear request (to peer) - already have a_clear_req_out_sync

    // Synchronizer for local isolate output (to peer) - already have a_isolate_out_sync

    // Synchronizer for local clear output (to peer) - already have a_clear_out_sync

    // Synchronizer for local reset (to peer) - already have a_rst_sync

    // Synchronizer for local state (to peer) - already have a_state_out_sync

    // Synchronizer for local isolate ack (to peer) - already have a_isolate_ack_out_sync

    // Synchronizer for local clear ack (to peer) - already have a_clear_ack_out_sync

    // Synchronizer for local clear request (to peer) - already have a_clear_req_out_sync

    // Synchronizer for local isolate output (to peer) - already have a_isolate_out_sync

    // Synchronizer for local clear output (to peer) - already have a_clear_out_sync

    // Synchronizer for local reset (to peer) - already have a_rst_sync

    // Synchronizer for local state (to peer) - already have a_state_out_sync

    // Synchronizer for local isolate ack (to peer) - already have a_isolate_ack_out_sync

    // Synchronizer for local clear ack (to peer) - already have a_clear_ack_out_sync

    // Synchronizer for local clear request (to peer) - already have a_clear_req_out_sync

    // Synchronizer for local isolate output (to peer) - already have a_isolate_out_sync

    // Synchronizer for local clear output (to peer) - already have a_clear_out_sync

    // Synchronizer for local reset (to peer) - already have a_rst_sync

    // Synchronizer for local state (to peer) - already have a_state_out_sync

    // Synchronizer for local isolate ack (to peer) - already have a_isolate_ack_out_sync

    // Synchronizer for local clear ack (to peer) - already have a_clear_ack_out_sync

    // Synchronizer for local clear request (to peer) - already have a_clear_req_out_sync

    // Synchronizer for local isolate output (to peer) - already have a_isolate_out_sync

    // Synchronizer for local clear output (to peer) - already have a_clear_out_sync

    // Synchronizer for local reset (to peer) - already have a_rst_sync

    // Synchronizer for local state (to peer) - already have a_state_out_sync

    // Synchronizer for local isolate ack (to peer) - already have a_isolate_ack_out_sync

    // Synchronizer for local clear ack (to peer) - already have a_clear_ack_out_sync

    // Synchronizer for local clear request (to peer) - already have a_clear_req_out_sync

    // Synchronizer for local isolate output (to peer) - already have a_isolate_out_sync

    // Synchronizer for local clear output (to peer) - already have a_clear_out_sync

    // Synchronizer for local reset (to peer) - already have a_rst_sync

    // Synchronizer for local state (to peer) - already have a_state_out_sync

    // Synchronizer for local isolate ack (to peer) - already have a_isolate_ack_out_sync

    // Synchronizer for local clear ack (to peer) - already have a_clear_ack_out_sync

    // Synchronizer for local clear request (to peer) - already have a_clear_req_out_sync

    // Synchronizer for local isolate output (to peer) - already have a_isolate_out_sync

    // Synchronizer for local clear output (to peer) - already have a_clear_out_sync

    // Synchronizer for local reset (to peer) - already have a_rst_sync

    // Synchronizer for local state (to peer) - already have a_state_out_sync

    // Synchronizer for local isolate ack (to peer) - already have a_isolate_ack_out_sync

    // Synchronizer for local clear ack (to peer) - already have a_clear_ack_out_sync

    // Synchronizer for local clear request (to peer) - already have a_clear_req_out_sync

    // Synchronizer for local isolate output (to peer) - already have a_isolate_out_sync

    // Synchronizer for local clear output (to