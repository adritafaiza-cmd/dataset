module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  logic edge_synced;
  logic edge_d;
  logic edge_pulse;

  // Instantiate the synchronization flip-flop module
  ff_sync ff_sync_tx_to_rx (
    .clk_src_i  (clk_tx_i),
    .rstn_src_i (rstn_tx_i),
    .data_i     (edge_i),
    .clk_dst_i  (clk_rx_i),
    .rstn_dst_i (rstn_rx_i),
    .data_o     (edge_synced)
  );

  // Detect the rising edge of edge_synced
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      edge_d <= 1'b0;
    end else begin
      edge_d <= edge_synced;
    end
  end

  assign edge_pulse = edge_synced & ~edge_d;

  // Output the pulse as edge_o
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      edge_o <= 1'b0;
    end else begin
      edge_o <= edge_pulse;
    end
  end

endmodule

module ff_sync (
  input  logic clk_src_i,
  input  logic rstn_src_i,
  input  logic data_i,
  input  logic clk_dst_i,
  input  logic rstn_dst_i,
  output logic data_o
);

  logic data_sync;

  // First stage of synchronization
  always_ff @(posedge clk_src_i or negedge rstn_src_i) begin
    if (!rstn_src_i) begin
      data_sync <= 1'b0;
    end else begin
      data_sync <= data_i;
    end
  end

  // Second stage of synchronization
  always_ff @(posedge clk_dst_i or negedge rstn_dst_i) begin
    if (!rstn_dst_i) begin
      data_o <= 1'b0;
    end else begin
      data_o <= data_sync;
    end
  end

endmodule
