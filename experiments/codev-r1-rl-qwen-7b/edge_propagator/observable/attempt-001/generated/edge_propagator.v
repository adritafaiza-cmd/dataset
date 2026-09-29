module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // TX domain: toggle on edge_i
  reg toggle_tx;

  always @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      toggle_tx <= 1'b0;
    end else if (edge_i) begin
      toggle_tx <= ~toggle_tx;
    end
  end

  // RX domain: synchronize toggle_tx and detect edge
  reg sync1, sync2, sync_prev;

  always @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      sync1 <= 1'b0;
      sync2 <= 1'b0;
      sync_prev <= 1'b0;
    end else begin
      sync1 <= toggle_tx;
      sync2 <= sync1;
      sync_prev <= sync2;
    end
  end

  assign edge_o = (sync2 != sync_prev);

endmodule
