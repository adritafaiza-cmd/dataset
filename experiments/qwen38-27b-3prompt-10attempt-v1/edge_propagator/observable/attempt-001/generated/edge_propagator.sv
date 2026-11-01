module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // TX domain: capture edge_i and generate a toggle
  logic tx_toggle;
  logic tx_toggle_next;

  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i)
      tx_toggle <= 1'b0;
    else if (edge_i)
      tx_toggle <= ~tx_toggle;
  end

  // Synchronize tx_toggle into RX domain
  logic rx_sync0, rx_sync1, rx_sync2;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      rx_sync0 <= 1'b0;
      rx_sync1 <= 1'b0;
      rx_sync2 <= 1'b0;
    end else begin
      rx_sync0 <= tx_toggle;
      rx_sync1 <= rx_sync0;
      rx_sync2 <= rx_sync1;
    end
  end

  // Detect toggle in RX domain and generate a single-cycle pulse
  logic rx_toggle_prev;
  logic rx_edge;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i)
      rx_toggle_prev <= 1'b0;
    else
      rx_toggle_prev <= rx_sync2;
  end

  assign rx_edge = rx_sync2 ^ rx_toggle_prev;

  // Output the edge pulse
  assign edge_o = rx_edge;

endmodule
