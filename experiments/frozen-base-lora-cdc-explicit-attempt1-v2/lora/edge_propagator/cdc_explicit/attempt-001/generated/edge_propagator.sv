// =============================================================================
// edge_propagator.sv
// =============================================================================
//
// Purpose:
//   Propagate a single-cycle pulse (or edge) from the TX clock domain to the
//   RX clock domain without losing or duplicating isolated edges.
//
// Architecture:
//   TX side:
//     - Detect a rising edge on edge_i.
//     - Toggle a single-bit "event" flag (tx_toggle) on each detected edge.
//
//   RX side:
//     - Synchronize tx_toggle through a 2-stage synchronizer.
//     - Detect a rising edge on the synchronized flag.
//     - Drive a single-cycle pulse on edge_o.
//
//   Because the TX side only toggles (never sets/clears), the RX side sees a
//   monotonically changing bit.  A 2-stage synchronizer is sufficient for a
//   single-bit signal.  The RX edge detector converts each toggle into one
//   pulse.
//
//   Reset behavior:
//     - After reset, tx_toggle is 0 and edge_o is 0.
//     - If an edge occurs during reset, it is lost (acceptable per spec).
//
// =============================================================================

`default_nettype none

module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,

  input  logic clk_rx_i,
  input  logic rstn_rx_i,

  output logic edge_o
);

  // --------------------------------------------------------------------------
  // TX domain: edge detect + toggle
  // --------------------------------------------------------------------------
  logic edge_i_d1;
  logic edge_i_rise;
  logic tx_toggle;

  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      edge_i_d1   <= 1'b0;
      tx_toggle   <= 1'b0;
    end else begin
      edge_i_d1   <= edge_i;
      edge_i_rise <= edge_i & ~edge_i_d1;
      if (edge_i_rise)
        tx_toggle <= ~tx_toggle;
    end
  end

  // --------------------------------------------------------------------------
  // RX domain: 2-stage synchronizer + edge detect
  // --------------------------------------------------------------------------
  logic tx_toggle_s1, tx_toggle_s2;
  logic tx_toggle_s2_d1;
  logic tx_toggle_rise;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      tx_toggle_s1   <= 1'b0;
      tx_toggle_s2   <= 1'b0;
      tx_toggle_s2_d1 <= 1'b0;
    end else begin
      tx_toggle_s1   <= tx_toggle;
      tx_toggle_s2   <= tx_toggle_s1;
      tx_toggle_s2_d1 <= tx_toggle_s2;
      tx_toggle_rise <= tx_toggle_s2 & ~tx_toggle_s2_d1;
    end
  end

  assign edge_o = tx_toggle_rise;

endmodule

`default_nettype wire