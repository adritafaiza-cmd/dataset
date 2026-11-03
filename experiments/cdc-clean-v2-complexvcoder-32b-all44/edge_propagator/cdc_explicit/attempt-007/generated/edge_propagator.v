module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // Internal signals
  logic edge_i_sync;
  logic edge_i_meta;
  logic edge_detected;

  // Synchronizer from TX domain to RX domain
  sync_cell sync_cell_inst (
    .clk(clk_rx_i),
    .rstn(rstn_rx_i),
    .d(edge_i),
    .q(edge_i_sync)
  );

  // Edge detector in RX domain
  edge_detector edge_detector_inst (
    .clk(clk_rx_i),
    .rstn(rstn_rx_i),
    .data_in(edge_i_sync),
    .edge_out(edge_detected)
  );

  // Output assignment
  assign edge_o = edge_detected;

endmodule

// Synchronizer module
module sync_cell (
  input  logic clk,
  input  logic rstn,
  input  logic d,
  output logic q
);

  // Internal signal
  logic meta;

  // Two-stage synchronizer
  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      meta <= 1'b0;
      q    <= 1'b0;
    end else begin
      meta <= d;
      q    <= meta;
    end
  end

endmodule

// Edge detector module
module edge_detector (
  input  logic clk,
  input  logic rstn,
  input  logic data_in,
  output logic edge_out
);

  // Internal signal
  logic data_in_prev;

  // Edge detection logic
  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      data_in_prev <= 1'b0;
      edge_out     <= 1'b0;
    end else begin
      data_in_prev <= data_in;
      edge_out     <= data_in & ~data_in_prev;
    end
  end

endmodule
