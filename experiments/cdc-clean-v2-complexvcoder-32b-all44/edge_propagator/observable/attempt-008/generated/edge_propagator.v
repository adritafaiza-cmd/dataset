module async_ff (
  input  logic clk_i,
  input  logic rstn_i,
  input  logic d_i,
  output logic q_o
);
  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
      q_o <= 1'b0;
    end else begin
      q_o <= d_i;
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
  logic edge_synced;
  logic edge_stable;
  logic edge_o_reg;
  logic edge_stable_ff;

  async_ff ff_tx (
    .clk_i  (clk_tx_i),
    .rstn_i (rstn_tx_i),
    .d_i    (edge_i),
    .q_o    (edge_synced)
  );

  async_ff ff_rx (
    .clk_i  (clk_rx_i),
    .rstn_i (rstn_rx_i),
    .d_i    (edge_synced),
    .q_o    (edge_stable)
  );

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      edge_o_reg <= 1'b0;
      edge_stable_ff <= 1'b0;
    end else begin
      edge_stable_ff <= edge_stable;
      if (edge_stable && !edge_stable_ff) begin
        edge_o_reg <= 1'b1;
      end else begin
        edge_o_reg <= 1'b0;
      end
    end
  end

  assign edge_o = edge_o_reg;
endmodule
