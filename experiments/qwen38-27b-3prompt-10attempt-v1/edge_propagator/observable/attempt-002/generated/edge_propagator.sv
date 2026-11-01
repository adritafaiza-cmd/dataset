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
  logic tx_toggle_d;

  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      tx_toggle   <= 1'b0;
      tx_toggle_d <= 1'b0;
    end else begin
      tx_toggle_d <= tx_toggle;
      if (edge_i)
        tx_toggle <= ~tx_toggle;
    end
  end

  // Synchronize tx_toggle into RX domain
  logic rx_sync0;
  logic rx_sync1;
  logic rx_sync2;

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

  // Detect edge on synchronized signal
  logic rx_toggle_d;
  logic edge_o;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      rx_toggle_d <= 1'b0;
      edge_o      <= 1'b0;
    end else begin
      rx_toggle_d <= rx_sync2;
      edge_o      <= (rx_sync2 != rx_toggle_d);
    end
  end

endmodule
