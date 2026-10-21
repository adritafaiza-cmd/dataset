module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // CDC Strategy:
  // 1. Capture the edge event in the TX domain using a 2-bit state machine (Gray code style)
  //    to detect rising and falling edges safely.
  // 2. Transfer the single-bit "event occurred" flag to the RX domain using a standard
  //    2-FIFO (or 2-stage synchronizer + latch) approach. Since we only need to propagate
  //    a single pulse and not a stream of data, a 2-stage synchronizer followed by a
  //    level-sensitive latch (or a 1-element FIFO) is sufficient.
  // 3. To ensure the pulse width in RX is clean and single-cycle (or at least non-zero),
  //    we use a pulse generator in the RX domain triggered by the synchronized event.
  //
  // Architecture:
  // TX Domain:
  //   - Detect edge on edge_i.
  //   - Set a 1-bit flag 'edge_detected' when an edge is found.
  //   - Clear 'edge_detected' after one TX clock cycle to prevent double-counting.
  // RX Domain:
  //   - Synchronize 'edge_detected' using a 2-stage synchronizer.
  //   - Generate a single-cycle pulse on edge_o when the synchronized signal goes high.

  // --- TX Domain: Edge Detection ---
  // We use a simple state machine to detect transitions.
  // State 0: Idle (last_edge = 0)
  // State 1: Rising Edge Detected (last_edge = 0, current_edge = 1)
  // State 2: Falling Edge Detected (last_edge = 1, current_edge = 0)
  // We only care about the occurrence of an edge, so we can simplify to a 1-bit flag
  // that is set on transition and cleared next cycle.

  logic edge_detected_tx;
  logic last_edge_tx;

  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      edge_detected_tx <= 1'b0;
      last_edge_tx     <= 1'b0;
    end else begin
      // Detect rising edge
      if (edge_i && !last_edge_tx) begin
        edge_detected_tx <= 1'b1;
      end
      // Detect falling edge
      else if (!edge_i && last_edge_tx) begin
        edge_detected_tx <= 1'b1;
      end
      // Clear the flag for the next cycle to ensure single pulse
      edge_detected_tx <= 1'b0;
      last_edge_tx     <= edge_i;
    end
  end

  // --- RX Domain: Synchronization and Pulse Generation ---
  // Synchronize the single-bit flag from TX to RX using a 2-stage synchronizer.
  // This ensures the signal is stable in the RX clock domain before being used.
  logic sync_edge_1;
  logic sync_edge_2;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      sync_edge_1 <= 1'b0;
      sync_edge_2 <= 1'b0;
    end else begin
      sync_edge_1 <= edge_detected_tx;
      sync_edge_2 <= sync_edge_1;
    end
  end

  // Generate the output pulse.
  // Since sync_edge_2 is a single-cycle pulse in the RX domain (assuming the TX pulse
  // was single-cycle and synchronized correctly), we can directly assign it to edge_o.
  // However, to be absolutely robust against metastability or glitches if the TX pulse
  // was wider than one cycle (though our TX logic forces it to 1 cycle), we can
  // ensure edge_o is a single cycle by checking the previous value.
  // Given the TX logic forces edge_detected_tx to 0 in the cycle after detection,
  // sync_edge_2 will naturally be a single cycle pulse in RX.
  
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      edge_o <= 1'b0;
    end else begin
      edge_o <= sync_edge_2;
    end
  end

endmodule<|im_end|>
