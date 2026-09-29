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
    end else begin
      if (edge_i) begin
        tx_toggle <= ~tx_toggle;
      end
    end
  end

  // RX domain: synchronization and edge detection
  reg rx_meta, rx_sync, rx_prev;

  always @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      rx_meta <= 1'b0;
      rx_sync <= 1'b0;
      rx_prev <= 1'b0;
    end else begin
      rx_meta <= tx_toggle;
      rx_sync <= rx_meta;
      rx_prev <= rx_sync;
    end
  end

  assign edge_o = (rx_sync ^ rx_prev);

endmodule
