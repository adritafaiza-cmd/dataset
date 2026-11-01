module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // TX domain: detect edge and generate a toggle
  logic tx_toggle;
  logic tx_toggle_next;

  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i)
      tx_toggle <= 1'b0;
    else
      tx_toggle <= tx_toggle_next;
  end

  always_comb begin
    tx_toggle_next = edge_i ? ~tx_toggle : tx_toggle;
  end

  // RX domain: synchronize the toggle signal
  logic rx_sync0, rx_sync1, rx_sync2;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      rx_sync0 <= 1'b0;
      rx_sync1 <= 1'b0;
      rx_sync2 <= 1'b0;
    end
    else begin
      rx_sync0 <= tx_toggle;
      rx_sync1 <= rx_sync0;
      rx_sync2 <= rx_sync1;
    end
  end

  // Detect edge on synchronized toggle and generate pulse
  logic rx_toggle;
  logic rx_toggle_next;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i)
      rx_toggle <= 1'b0;
    else
      rx_toggle <= rx_toggle_next;
  end

  always_comb begin
    rx_toggle_next = (rx_sync2 != rx_toggle) ? ~rx_toggle : rx_toggle;
  end

  // Generate output pulse when rx_toggle changes
  assign edge_o = rx_toggle ^ rx_sync2;

endmodule
