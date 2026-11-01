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

  // Synchronize tx_toggle into RX domain (2-FF synchronizer)
  logic sync1, sync2;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      sync1 <= 1'b0;
      sync2 <= 1'b0;
    end else begin
      sync1 <= tx_toggle;
      sync2 <= sync1;
    end
  end

  // RX domain: detect toggle on sync2 and generate a single-cycle pulse
  logic sync2_prev;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i)
      sync2_prev <= 1'b0;
    else
      sync2_prev <= sync2;
  end

  assign edge_o = sync2 ^ sync2_prev;

endmodule
