module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // Internal signals
  logic edge_tx_to_rx_synced;
  logic edge_rx_to_tx_synced;
  logic edge_tx_to_rx;
  logic edge_rx_to_tx;

  // Detect edges on edge_i in the TX domain
  logic edge_i_prev;
  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      edge_i_prev <= 1'b0;
      edge_tx_to_rx <= 1'b0;
    end else begin
      edge_i_prev <= edge_i;
      edge_tx_to_rx <= edge_i & ~edge_i_prev;
    end
  end

  // Synchronize edge_tx_to_rx to the RX domain
  sync_flop sync_edge_tx_to_rx (
    .clk_i  (clk_rx_i),
    .rstn_i (rstn_rx_i),
    .d_i    (edge_tx_to_rx),
    .q_o    (edge_tx_to_rx_synced)
  );

  // Detect edges on edge_tx_to_rx_synced in the RX domain
  logic edge_tx_to_rx_synced_prev;
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      edge_tx_to_rx_synced_prev <= 1'b0;
      edge_o <= 1'b0;
    end else begin
      edge_tx_to_rx_synced_prev <= edge_tx_to_rx_synced;
      edge_o <= edge_tx_to_rx_synced & ~edge_tx_to_rx_synced_prev;
    end
  end

  // Synchronize edge_o back to the TX domain
  sync_flop sync_edge_rx_to_tx (
    .clk_i  (clk_tx_i),
    .rstn_i (rstn_tx_i),
    .d_i    (edge_o),
    .q_o    (edge_rx_to_tx_synced)
  );

endmodule

// Synchronization flop module
module sync_flop (
  input  logic clk_i,
  input  logic rstn_i,
  input  logic d_i,
  output logic q_o
);

  // Internal signal
  logic q_int;

  // Synchronize using two flops
  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
      q_int <= 1'b0;
      q_o <= 1'b0;
    end else begin
      q_int <= d_i;
      q_o <= q_int;
    end
  end

endmodule
