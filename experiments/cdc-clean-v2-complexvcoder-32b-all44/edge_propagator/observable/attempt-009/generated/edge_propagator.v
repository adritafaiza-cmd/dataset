module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  logic edge_tx;
  logic edge_rx;

  async_ff ff_tx (
    .clk(clk_tx_i),
    .rstn(rstn_tx_i),
    .d(edge_i),
    .q(edge_tx)
  );

  async_ff ff_rx (
    .clk(clk_rx_i),
    .rstn(rstn_rx_i),
    .d(edge_tx),
    .q(edge_rx)
  );

  edge_detector edge_det (
    .clk(clk_rx_i),
    .rstn(rstn_rx_i),
    .signal(edge_rx),
    .edge(edge_o)
  );

endmodule

module async_ff (
  input  logic clk,
  input  logic rstn,
  input  logic d,
  output logic q
);

  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      q <= 1'b0;
    end else begin
      q <= d;
    end
  end

endmodule

module edge_detector (
  input  logic clk,
  input  logic rstn,
  input  logic signal,
  output logic edge
);

  logic signal_reg;

  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      signal_reg <= 1'b0;
      edge <= 1'b0;
    end else begin
      signal_reg <= signal;
      edge <= signal & ~signal_reg;
    end
  end

endmodule
