module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  logic edge_sync;

  // Synchronizer flip-flop module
  ff_sync ff_sync_inst (
    .clk_i(clk_tx_i),
    .rstn_i(rstn_tx_i),
    .data_i(edge_i),
    .clk_o(clk_rx_i),
    .data_o(edge_sync)
  );

  // Edge detector module
  edge_detector edge_detector_inst (
    .clk_i(clk_rx_i),
    .rstn_i(rstn_rx_i),
    .signal_i(edge_sync),
    .edge_o(edge_o)
  );

endmodule

// Synchronizer flip-flop module
module ff_sync (
  input  logic clk_i,
  input  logic rstn_i,
  input  logic data_i,
  input  logic clk_o,
  output logic data_o
);

  logic sync_ff1;
  logic sync_ff2;

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
      sync_ff1 <= 1'b0;
    end else begin
      sync_ff1 <= data_i;
    end
  end

  always_ff @(posedge clk_o or negedge rstn_i) begin
    if (!rstn_i) begin
      sync_ff2 <= 1'b0;
    end else begin
      sync_ff2 <= sync_ff1;
    end
  end

  assign data_o = sync_ff2;

endmodule

// Edge detector module
module edge_detector (
  input  logic clk_i,
  input  logic rstn_i,
  input  logic signal_i,
  output logic edge_o
);

  logic signal_reg;

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
      signal_reg <= 1'b0;
    end else begin
      signal_reg <= signal_i;
    end
  end

  assign edge_o = (signal_i & ~signal_reg);

endmodule
