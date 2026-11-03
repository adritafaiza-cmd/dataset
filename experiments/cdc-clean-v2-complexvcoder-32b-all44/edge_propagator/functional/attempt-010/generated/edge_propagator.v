module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  logic edge_sync;
  logic edge_detected_sync;

  // Synchronize the edge_i signal to the RX domain
  ff_sync ff_sync_edge (
    .clk_i(clk_tx_i),
    .rstn_i(rstn_tx_i),
    .data_i(edge_i),
    .clk_o(clk_rx_i),
    .rstn_o(rstn_rx_i),
    .sync_data_o(edge_sync)
  );

  // Detect the edge in the synchronized signal
  edge_detector edge_detector_sync (
    .clk_i(clk_rx_i),
    .rstn_i(rstn_rx_i),
    .data_i(edge_sync),
    .edge_detected(edge_detected_sync)
  );

  // Synchronize the edge detected signal to the RX domain
  ff_sync ff_sync_edge_detected (
    .clk_i(clk_rx_i),
    .rstn_i(rstn_rx_i),
    .data_i(edge_detected_sync),
    .clk_o(clk_rx_i),
    .rstn_o(rstn_rx_i),
    .sync_data_o(edge_o)
  );

endmodule

module ff_sync (
  input  logic clk_i,
  input  logic rstn_i,
  input  logic data_i,
  input  logic clk_o,
  input  logic rstn_o,
  output logic sync_data_o
);

  logic ff1;
  logic ff2;

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
      sync_data_o <= 1'b0;
    end else begin
      sync_data_o <= ff2;
    end
  end

endmodule

module edge_detector (
  input  logic clk_i,
  input  logic rstn_i,
  input  logic data_i,
  output logic edge_detected
);

  logic data_ff;

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
      data_ff <= 1'b0;
      edge_detected <= 1'b0;
    end else begin
      data_ff <= data_i;
      edge_detected <= data_i & ~data_ff;
    end
  end

endmodule
