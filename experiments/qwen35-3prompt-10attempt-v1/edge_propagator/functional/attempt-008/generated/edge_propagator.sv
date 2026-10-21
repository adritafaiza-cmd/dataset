module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // TX Domain: Detect edges on edge_i
  logic tx_edge_detected;
  logic tx_edge_prev;

  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      tx_edge_prev <= 1'b0;
      tx_edge_detected <= 1'b0;
    end else begin
      tx_edge_prev <= edge_i;
      // Detect rising or falling edge
      tx_edge_detected <= (edge_i ^ tx_edge_prev);
    end
  end

  // RX Domain: Capture the edge and generate a single pulse
  logic rx_edge_latched;
  logic rx_edge_prev;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      rx_edge_latched <= 1'b0;
      rx_edge_prev <= 1'b0;
      edge_o <= 1'b0;
    end else begin
      // Capture the detected edge from TX domain
      rx_edge_latched <= tx_edge_detected;
      
      // Generate pulse: output high if current latched value differs from previous
      // This ensures exactly one pulse per edge regardless of TX pulse width
      edge_o <= (rx_edge_latched ^ rx_edge_prev);
      rx_edge_prev <= rx_edge_latched;
    end
  end

endmodule<|im_end|>
