// =============================================================================
// cdc_reset_ctrlr.v
// =============================================================================
// Two-domain isolate-then-clear reset controller.
//
// Protocol (per side, driven by the local FSM):
//   1. Local *_clear_i asserted -> raise local *_isolate_o.
//   2. Wait for local *_isolate_ack_i.
//   3. Raise local *_clear_o.
//   4. Wait for local *_clear_ack_i.
//   5. Drop local *_clear_o.
//   6. Drop local *_isolate_o.
//
// The two sides are coupled through a 4-state status handshake that is
// synchronised across the clock-domain boundary.  Each side publishes its
// own status (IDLE / ISOLATE / CLEAR / RELEASE) and consumes the peer's
// status.  A side may only advance to the next step after the peer has
// been observed in the corresponding state, guaranteeing that neither
// domain is cleared while the other is still live.
// =============================================================================

`include "cdc_reset_ctrlr.vh"

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

    // ------------------------------------------------------------------
    // Status encoding (2 bits, one-hot)
    // ------------------------------------------------------------------
    localparam [1:0] ST_IDLE    = 2'b00;
    localparam [1:0] ST_ISOLATE = 2'b01;
    localparam [1:0] ST_CLEAR   = 2'b10;
    localparam [1:0] ST_RELEASE = 2'b11;

    // ------------------------------------------------------------------
    // Side A (a_clk domain)
    // ------------------------------------------------------------------
    reg  [1:0] a_status_r;
    reg  [1:0] a_peer_status_r;

    wire       a_isolate_o;
    wire       a_clear_o;

    cdc_reset_side #(
        .SYNC_STAGES(SYNC_STAGES)
    ) u_a_side (
        .clk_i          (a_clk_i),
        .rst_ni         (a_rst_ni),
        .clear_i        (a_clear_i),
        .clear_ack_i    (a_clear_ack_i),
        .isolate_ack_i  (a_isolate_ack_i),
        .status_o       (a_status_r),
        .peer_status_i  (a_peer_status_r),
        .isolate_o      (a_isolate_o),
        .clear_o        (a_clear_o)
    );

    // ------------------------------------------------------------------
    // Side B (b_clk domain)
    // ------------------------------------------------------------------
    reg  [1:0] b_status_r;
    reg  [1:0] b_peer_status_r;

    wire       b_isolate_o;
    wire       b_clear_o;

    cdc_reset_side #(
        .SYNC_STAGES(SYNC_STAGES)
    ) u_b_side (
        .clk_i          (b_clk_i),
        .rst_ni         (b_rst_ni),
        .clear_i        (b_clear_i),
        .clear_ack_i    (b_clear_ack_i),
        .isolate_ack_i  (b_isolate_ack_i),
        .status_o       (b_status_r),
        .peer_status_i  (b_peer_status_r),
        .isolate_o      (b_isolate_o),
        .clear_o        (b_clear_o)
    );

    // ------------------------------------------------------------------
    // CDC: A -> B status (2-bit, synchronised)
    // ------------------------------------------------------------------
    cdc_sync #(
        .WIDTH      (2),
        .SYNC_STAGES(SYNC_STAGES)
    ) u_a2b_status (
        .clk_i    (b_clk_i),
        .rst_ni   (b_rst_ni),
        .data_i   (a_status_r),
        .data_o   (b_peer_status_r)
    );

    // ------------------------------------------------------------------
    // CDC: B -> A status (2-bit, synchronised)
    // ------------------------------------------------------------------
    cdc_sync #(
        .WIDTH      (2),
        .SYNC_STAGES(SYNC_STAGES)
    ) u_b2a_status (
        .clk_i    (a_clk_i),
        .rst_ni   (a_rst_ni),
        .data_i   (b_status_r),
        .data_o   (a_peer_status_r)
    );

endmodule