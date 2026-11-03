module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // Internal signals for clock-domain crossing
  logic edge_i_sync;
  logic edge_i_sync_stable;
  logic edge_o_reg;
  logic edge_o_reg_prev;

  // First stage of synchronization
  ff_sync ff_sync_tx (
    .clk_i  (clk_rx_i),
    .rstn_i (rstn_rx_i),
    .d_i    (edge_i),
    .q_o    (edge_i_sync)
  );

  // Second stage of synchronization
  ff_sync ff_sync_rx (
    .clk_i  (clk_rx_i),
    .rstn_i (rstn_rx_i),
    .d_i    (edge_i_sync),
    .q_o    (edge_i_sync_stable)
  );

  // Detect rising edge on synchronized signal
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      edge_o_reg <= 0;
    end else begin
      edge_o_reg <= edge_i_sync_stable;
    end
  end

  // Detect transition of edge_o_reg from 0 to 1
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      edge_o_reg_prev <= 0;
      edge_o <= 0;
    end else begin
      edge_o_reg_prev <= edge_o_reg;
      edge_o <= edge_o_reg & ~edge_o_reg_prev;
    end
  end

endmodule

module ff_sync (
  input  logic clk_i,
  input  logic rstn_i,
  input  logic d_i,
  output logic q_o
);

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
      q_o <= 0;
    end else begin
      q_o <= d_i;
    end
  end

endmodule
