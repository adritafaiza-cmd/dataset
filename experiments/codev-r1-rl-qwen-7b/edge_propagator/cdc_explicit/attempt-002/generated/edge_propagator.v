module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // TX domain: Toggle on edge_i
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

  // RX domain: Synchronize and edge detection
  reg sync0, sync1, sync_prev;

  always @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      sync0 <= 1'b0;
      sync1 <= 1'b0;
      sync_prev <= 1'b0;
    end else begin
      sync_prev <= sync1;
      sync0 <= tx_toggle;
      sync1 <= sync0;
    end
  end

  assign edge_o = (sync1 != sync_prev);

endmodule
