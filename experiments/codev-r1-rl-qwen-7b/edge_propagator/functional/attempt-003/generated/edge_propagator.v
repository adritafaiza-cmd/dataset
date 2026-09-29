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

  // Synchronizer in RX domain
  reg sync1, sync2;

  always @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      sync1 <= 1'b0;
      sync2 <= 1'b0;
    end else begin
      sync1 <= tx_toggle;
      sync2 <= sync1;
    end
  end

  // Edge detection in RX domain
  reg sync_prev;

  always @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      sync_prev <= 1'b0;
    end else begin
      sync_prev <= sync2;
    end
  end

  assign edge_o = (sync2 ^ sync_prev);

endmodule
