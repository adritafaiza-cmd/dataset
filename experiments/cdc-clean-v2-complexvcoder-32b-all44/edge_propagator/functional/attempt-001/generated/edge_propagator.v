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

  async_edge_detector edge_detector_tx (
    .clk_i   (clk_tx_i),
    .rstn_i  (rstn_tx_i),
    .data_i  (edge_i),
    .edge_o  (edge_tx)
  );

  async_edge_detector edge_detector_rx (
    .clk_i   (clk_rx_i),
    .rstn_i  (rstn_rx_i),
    .data_i  (edge_tx),
    .edge_o  (edge_rx)
  );

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      edge_o <= 1'b0;
    end else begin
      edge_o <= edge_rx;
    end
  end

endmodule

module async_edge_detector (
  input  logic clk_i,
  input  logic rstn_i,
  input  logic data_i,
  output logic edge_o
);

  logic data_reg;

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
      data_reg <= 1'b0;
    end else begin
      data_reg <= data_i;
    end
  end

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
      edge_o <= 1'b0;
    end else begin
      edge_o <= data_i ^ data_reg;
    end
  end

endmodule
