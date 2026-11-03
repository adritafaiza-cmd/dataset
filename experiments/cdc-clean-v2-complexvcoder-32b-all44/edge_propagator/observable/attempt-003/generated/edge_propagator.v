module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // Internal signals
  logic tx_rstn_sync;
  logic rx_rstn_sync;
  logic edge_crossed;

  // Instantiate the async_reset_synchronizer to synchronize reset from tx to rx
  async_reset_synchronizer tx_reset_sync (
    .clk_i(clk_rx_i),
    .rstn_i(rstn_tx_i),
    .rstn_o(tx_rstn_sync)
  );

  // Instantiate the async_reset_synchronizer to synchronize reset from rx to tx
  async_reset_synchronizer rx_reset_sync (
    .clk_i(clk_tx_i),
    .rstn_i(rstn_rx_i),
    .rstn_o(rx_rstn_sync)
  );

  // Instantiate the async_level_crossing to cross the edge signal from tx to rx
  async_level_crossing edge_cross (
    .clk_src_i(clk_tx_i),
    .clk_dst_i(clk_rx_i),
    .level_i(edge_i),
    .level_o(edge_crossed)
  );

  // Instantiate the edge_detector to detect the rising edge of the crossed signal in the rx domain
  edge_detector edge_det (
    .clk_i(clk_rx_i),
    .rstn_i(rstn_rx_i),
    .level_i(edge_crossed),
    .edge_o(edge_o)
  );

endmodule

// Synchronize an active-low reset signal between two clock domains
module async_reset_synchronizer (
  input  logic clk_i,
  input  logic rstn_i,
  output logic rstn_o
);

  // Internal signals for double synchronization
  logic rstn_sync1;
  logic rstn_sync2;

  // Synchronization flops
  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
      rstn_sync1 <= 1'b1;
      rstn_sync2 <= 1'b1;
    end else begin
      rstn_sync1 <= rstn_i;
      rstn_sync2 <= rstn_sync1;
    end
  end

  // Output the synchronized reset
  assign rstn_o = rstn_sync2;

endmodule

// Cross a level signal between two asynchronous clock domains
module async_level_crossing (
  input  logic clk_src_i,
  input  logic clk_dst_i,
  input  logic level_i,
  output logic level_o
);

  // Internal signal for synchronization
  logic level_sync1;

  // Synchronization flops
  always_ff @(posedge clk_src_i) begin
    level_sync1 <= level_i;
  end

  always_ff @(posedge clk_dst_i) begin
    level_o <= level_sync1;
  end

endmodule

// Detect a rising edge of a level signal in a given clock domain
module edge_detector (
  input  logic clk_i,
  input  logic rstn_i,
  input  logic level_i,
  output logic edge_o
);

  // Internal signal to register the previous level
  logic level_reg;

  // Register the current level and detect the rising edge
  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
      level_reg <= 1'b0;
      edge_o <= 1'b0;
    end else begin
      level_reg <= level_i;
      edge_o <= level_i & ~level_reg;
    end
  end

endmodule
