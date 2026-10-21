```systemverilog
module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // Synchronizer for the input event signal on the transmit clock domain
  // We use a 2-stage synchronizer to filter out metastability before capturing the edge
  logic sync_edge_1;
  logic sync_edge_2;

  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      sync_edge_1 <= 1'b0;
      sync_edge_2 <= 1'b0;
    end else begin
      sync_edge_1 <= edge_i;
      sync_edge_2 <= sync_edge_1;
    end
  end

  // Detect the rising edge of the synchronized signal on the TX domain
  logic tx_edge_detected;
  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      tx_edge_detected <= 1'b0;
    end else begin
      tx_edge_detected <= sync_edge_2 & ~sync_edge_1;
    end
  end

  // Clock domain crossing: Move the edge detection from TX domain to RX domain
  // Using a 2-stage synchronizer for the edge flag
  logic rx_sync_edge_1;
  logic rx_sync_edge_2;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      rx_sync_edge_1 <= 1'b0;
      rx_sync_edge_2 <= 1'b0;
    end else begin
      rx_sync_edge_1 <= tx_edge_detected;
      rx_sync_edge_2 <= rx_sync_edge_1;
    end
  end

  // Output logic: Assert the edge on the RX domain only once per detected event
  // Ensure it stays low after the event is processed to avoid duplication
  // Since we are just propagating a single event, we can simply drive the output
  // based on the synchronized edge flag. To ensure it doesn't stay high indefinitely
  // or duplicate if the synchronizer glitches, we treat the arrival of the signal
  // as the event. However, the requirement says "without duplicating it".
  // A simple latch or flip-flop driven by the synchronized edge is sufficient.
  // To be safe against the synchronizer holding '1' for a cycle, we can use a pulse generator
  // or simply drive the output directly if the downstream logic expects a level.
  // Given "carry an input event... as one event", a single-cycle pulse is usually the cleanest interpretation
  // of an "event" in this context, preventing stale levels.

  logic rx_pulse;
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      rx_pulse <= 1'b0;
    end else begin
      // Capture the edge arrival
      rx_pulse <= rx_sync_edge_2;
    end
  end

  // Convert the level to a single-cycle pulse to ensure no duplication and clean reset behavior
  // If rx_sync_edge_2 is 1, we assert pulse. If it was already 1, we don't re-assert.
  // Actually, a simpler approach for "one event" is to just drive the output high when the signal arrives
  // and let the downstream handle it, OR generate a one-shot.
  // Let's implement a one-shot to guarantee a single pulse event.
  
  logic pulse_gen;
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      pulse_gen <= 1'b0;
    end else begin
      // If the synchronized edge is present and we are not currently in the pulse state, generate it
      if (rx_sync_edge_2 && !pulse_gen) begin
        pulse_gen <= 1'b1;
      end else begin
        pulse_gen <= 1'b0;
      end
    end
  end

  assign edge_o = pulse_gen;

endmodule
```<|im_end|>
