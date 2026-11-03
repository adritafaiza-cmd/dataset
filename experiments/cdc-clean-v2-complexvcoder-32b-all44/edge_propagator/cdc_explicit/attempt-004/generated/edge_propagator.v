module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  logic edge_i_synced;

  async_ff ff_tx_to_rx (
    .clk_i  (clk_tx_i),
    .rstn_i (rstn_tx_i),
    .data_i (edge_i),
    .clk_o  (clk_rx_i),
    .rstn_o (rstn_rx_i),
    .data_o (edge_i_synced)
  );

  edge_detector edge_det_rx (
    .clk_i  (clk_rx_i),
    .rstn_i (rstn_rx_i),
    .data_i (edge_i_synced),
    .edge_o (edge_o)
  );

endmodule

module async_ff (
  input  logic clk_i,
  input  logic rstn_i,
  input  logic data_i,
  input  logic clk_o,
  input  logic rstn_o,
  output logic data_o
);

  logic ff1, ff2;

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
      ff1 <= 1'b0;
      ff2 <= 1'b0;
    end else begin
      ff1 <= data_i;
      ff2 <= ff1;
    end
  end

  always_ff @(posedge clk_o or negedge rstn_o) begin
    if (!rstn_o) begin
      data_o <= 1'b0;
    end else begin
      data_o <= ff2;
    end
  end

endmodule

module edge_detector (
  input  logic clk_i,
  input  logic rstn_i,
  input  logic data_i,
  output logic edge_o
);

  logic data_reg;

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
      data_reg <= 1'b0;
      edge_o   <= 1'b0;
    end else begin
      data_reg <= data_i;
      edge_o   <= data_i & ~data_reg;
    end
  end

endmodule
