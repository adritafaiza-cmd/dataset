module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // Internal state registers
  logic tx_edge_detected;
  logic rx_edge_detected;
  logic tx_edge_latched;
  logic rx_edge_latched;

  // TX Domain: Detect rising edge on edge_i
  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      tx_edge_detected <= 1'b0;
      tx_edge_latched <= 1'b0;
    end else begin
      tx_edge_detected <= edge_i;
      // Detect rising edge
      if (tx_edge_detected && !tx_edge_latched) begin
        tx_edge_latched <= 1'b1;
      end
    end
  end

  // RX Domain: Detect rising edge on edge_i (sampled in RX clock)
  // We need to sample the TX edge detection signal across the clock domain
  logic tx_edge_sampled;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      tx_edge_sampled <= 1'b0;
      rx_edge_detected <= 1'b0;
      rx_edge_latched <= 1'b0;
    end else begin
      tx_edge_sampled <= tx_edge_detected;
      // Detect rising edge of the sampled signal
      if (tx_edge_sampled && !rx_edge_detected) begin
        rx_edge_detected <= 1'b1;
      end
    end
  end

  // RX Domain: Generate single pulse on edge_o
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      edge_o <= 1'b0;
    end else begin
      // Pulse is generated when we detect an edge in RX domain
      // and cleared immediately after
      if (rx_edge_detected) begin
        edge_o <= 1'b1;
      end else begin
        edge_o <= 1'b0;
      end
    end
  end

endmodule<|im_end|>
