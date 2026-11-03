module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  logic edge_synced;
  logic edge_synced_ff;
  logic edge_detected;

  // Two-stage flip-flop synchronization from clk_tx_i to clk_rx_i
  ff_sync ff_sync_tx_to_rx (
    .clk_i     (clk_rx_i),
    .rstn_i    (rstn_rx_i),
    .async_in  (edge_i),
    .sync_out  (edge_synced)
  );

  // Two-stage flip-flop synchronization within clk_rx_i domain
  ff_sync ff_sync_rx (
    .clk_i     (clk_rx_i),
    .rstn_i    (rstn_rx_i),
    .async_in  (edge_synced),
    .sync_out  (edge_synced_ff)
  );

  // Detect rising edge of synchronized signal
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      edge_detected <= 1'b0;
      edge_o        <= 1'b0;
    end else begin
      edge_detected <= edge_synced & ~edge_synced_ff;
      edge_o        <= edge_detected;
    end
  end

endmodule

module ff_sync (
  input  logic clk_i,
  input  logic rstn_i,
  input  logic async_in,
  output logic sync_out
);

  logic ff1;
  logic ff2;

  // Two-stage synchronization
  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
      ff1 <= 1'b0;
      ff2 <= 1'b0;
    end else begin
      ff1 <= async_in;
      ff2 <= ff1;
    end
  end

  assign sync_out = ff2;

endmodule
