```systemverilog
module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // Synchronizer for the input event from the transmit clock domain
  // Uses a 2-stage synchronizer to filter out metastability
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

  // Pulse generator to create a single-cycle pulse on the receive clock domain
  // This ensures the event is propagated exactly once without duplication
  logic pulse_rx;
  logic pulse_rx_next;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      pulse_rx <= 1'b0;
      pulse_rx_next <= 1'b0;
    end else begin
      // If the synchronized event is high, generate a pulse
      if (sync_edge_2) begin
        pulse_rx <= 1'b1;
      end else begin
        pulse_rx <= pulse_rx_next;
      end
      pulse_rx_next <= 1'b0;
    end
  end

  // Assign the output directly from the generated pulse
  assign edge_o = pulse_rx;

endmodule
```<|im_end|>
