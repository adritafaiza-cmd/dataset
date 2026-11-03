module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  logic data_tx_to_rx;
  logic data_rx_stable;

  // Asynchronous flip-flop to cross the domain from clk_tx_i to clk_rx_i
  async_flipflop ff_tx (
    .clk(clk_tx_i),
    .rstn(rstn_tx_i),
    .data_in(edge_i),
    .data_out(data_tx_to_rx)
  );

  // Asynchronous flip-flop to stabilize the signal in clk_rx_i domain
  async_flipflop ff_rx (
    .clk(clk_rx_i),
    .rstn(rstn_rx_i),
    .data_in(data_tx_to_rx),
    .data_out(data_rx_stable)
  );

  // Edge detector to detect edges in the stabilized signal
  edge_detector edge_det (
    .clk(clk_rx_i),
    .rstn(rstn_rx_i),
    .data(data_rx_stable),
    .edge_o(edge_o)
  );

endmodule

module async_flipflop (
  input  logic clk,
  input  logic rstn,
  input  logic data_in,
  output logic data_out
);

  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      data_out <= 1'b0;
    end else begin
      data_out <= data_in;
    end
  end

endmodule

module edge_detector (
  input  logic clk,
  input  logic rstn,
  input  logic data,
  output logic edge_o
);

  logic data_prev;

  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      data_prev <= 1'b0;
      edge_o <= 1'b0;
    end else begin
      data_prev <= data;
      edge_o <= data & ~data_prev;
    end
  end

endmodule
