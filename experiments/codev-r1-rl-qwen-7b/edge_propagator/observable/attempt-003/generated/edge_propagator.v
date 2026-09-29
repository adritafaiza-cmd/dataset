module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // Toggle register in TX domain
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
  reg sync0, sync1;

  always @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      sync0 <= 1'b0;
      sync1 <= 1'b0;
    end else begin
      sync0 <= tx_toggle;
      sync1 <= sync0;
    end
  end

  // Edge detection in RX domain
  reg rx_toggle_prev;

  always @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      rx_toggle_prev <= 1'b0;
    end else begin
      rx_toggle_prev <= sync1;
    end
  end

  assign edge_o = (sync1 != rx_toggle_prev);

endmodule
