module asynchronous_edge_detector (
  input  logic clk_i,
  input  logic rstn_i,
  input  logic signal_i,
  output logic edge_o
);
  logic signal_reg, signal_reg2;

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
      signal_reg  <= 1'b0;
      signal_reg2 <= 1'b0;
      edge_o      <= 1'b0;
    end else begin
      signal_reg  <= signal_i;
      signal_reg2 <= signal_reg;
      edge_o      <= (signal_i != signal_reg2);
    end
  end
endmodule

module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);
  logic tx_edge, rx_edge_signal;

  asynchronous_edge_detector tx_edge_detector (
    .clk_i    (clk_tx_i),
    .rstn_i   (rstn_tx_i),
    .signal_i (edge_i),
    .edge_o   (tx_edge)
  );

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      rx_edge_signal <= 1'b0;
    end else begin
      rx_edge_signal <= tx_edge;
    end
  end

  asynchronous_edge_detector rx_edge_detector (
    .clk_i    (clk_rx_i),
    .rstn_i   (rstn_rx_i),
    .signal_i (rx_edge_signal),
    .edge_o   (edge_o)
  );
endmodule
