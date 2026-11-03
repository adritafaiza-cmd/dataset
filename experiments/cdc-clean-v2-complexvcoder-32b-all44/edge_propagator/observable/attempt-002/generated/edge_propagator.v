module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // Internal signals
  logic edge_tx_to_rx;
  logic edge_synced;
  logic edge_o_reg;
  logic edge_o_prev;

  // Synchronize edge signal from tx domain to rx domain
  ff_sync ff_sync_inst_tx_to_rx (
    .clk_i  (clk_rx_i),
    .rstn_i (rstn_rx_i),
    .d_i    (edge_tx_to_rx),
    .q_o    (edge_synced)
  );

  // Register edge_i in tx domain
  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      edge_tx_to_rx <= 1'b0;
    end else begin
      edge_tx_to_rx <= edge_i;
    end
  end

  // Detect edge transition in rx domain
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      edge_synced <= 1'b0;
      edge_o_reg  <= 1'b0;
      edge_o_prev <= 1'b0;
    end else begin
      edge_o_prev <= edge_synced;
      edge_o_reg  <= edge_synced & ~edge_o_prev;
    end
  end

  // Assign output
  assign edge_o = edge_o_reg;

endmodule

// Synchronizer module
module ff_sync (
  input  logic clk_i,
  input  logic rstn_i,
  input  logic d_i,
  output logic q_o
);

  // Internal registers
  logic q_reg1;
  logic q_reg2;

  // Two-stage flip-flop synchronizer
  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
      q_reg1 <= 1'b0;
      q_reg2 <= 1'b0;
    end else begin
      q_reg1 <= d_i;
      q_reg2 <= q_reg1;
    end
  end

  // Output assignment
  assign q_o = q_reg2;

endmodule
