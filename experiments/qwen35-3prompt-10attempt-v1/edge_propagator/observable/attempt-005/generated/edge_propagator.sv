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
  // We use a 2-stage synchronizer to filter out metastability
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

  // Pulse generator in the transmit domain to create a single-cycle pulse
  // This ensures the event is represented as a clean, single-cycle positive pulse
  logic tx_pulse;
  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      tx_pulse <= 1'b0;
    end else begin
      if (sync_edge_2 && !sync_edge_1) begin
        // Rising edge detected on the second stage -> generate pulse
        tx_pulse <= 1'b1;
      end else begin
        tx_pulse <= 1'b0;
      end
    end
  end

  // Synchronizer for the pulse from the transmit clock domain to the receive clock domain
  // We use a 2-stage synchronizer again
  logic rx_pulse_1;
  logic rx_pulse_2;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      rx_pulse_1 <= 1'b0;
      rx_pulse_2 <= 1'b0;
    end else begin
      rx_pulse_1 <= tx_pulse;
      rx_pulse_2 <= rx_pulse_1;
    end
  end

  // Output the synchronized pulse
  assign edge_o = rx_pulse_2;

endmodule
```<|im_end|>
