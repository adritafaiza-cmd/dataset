```systemverilog
module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // Synchronizer for the input event on the TX clock domain
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

  // Pulse generator on TX domain to create a single-cycle pulse
  // This ensures the event is captured as a clean, single-cycle event
  logic tx_pulse;
  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      tx_pulse <= 1'b0;
    end else begin
      if (sync_edge_2 && !sync_edge_1) begin
        tx_pulse <= 1'b1;
      end else begin
        tx_pulse <= 1'b0;
      end
    end
  end

  // Clock domain crossing to RX domain
  // We use a 2-stage synchronizer for the pulse signal
  logic rx_sync_pulse_1;
  logic rx_sync_pulse_2;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      rx_sync_pulse_1 <= 1'b0;
      rx_sync_pulse_2 <= 1'b0;
    end else begin
      rx_sync_pulse_1 <= tx_pulse;
      rx_sync_pulse_2 <= rx_sync_pulse_1;
    end
  end

  // Output logic on RX domain
  // The output follows the synchronized pulse
  // Since the pulse is single-cycle on TX, it will appear as a single-cycle pulse on RX
  // after the second stage of synchronization.
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      edge_o <= 1'b0;
    end else begin
      edge_o <= rx_sync_pulse_2;
    end
  end

endmodule
```<|im_end|>
