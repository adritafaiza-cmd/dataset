module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // TX domain: toggle on edge_i
  reg tx_toggle;

  always @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      tx_toggle <= 1'b0;
    end else if (edge_i) begin
      tx_toggle <= ~tx_toggle;
    end
  end

  // RX domain: synchronize the toggle
  reg rx_toggle_meta, rx_toggle_sync, rx_toggle_prev;

  always @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      rx_toggle_meta <= 1'b0;
      rx_toggle_sync <= 1'b0;
      rx_toggle_prev <= 1'b0;
    end else begin
      rx_toggle_meta <= tx_toggle;
      rx_toggle_sync <= rx_toggle_meta;
      rx_toggle_prev <= rx_toggle_sync;
    end
  end

  // Edge detection in RX domain
  assign edge_o = (rx_toggle_sync != rx_toggle_prev);

endmodule
