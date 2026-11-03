module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  logic async_edge;
  logic sync_edge;
  logic sync_edge_d;

  // FF to capture edge_i
  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      async_edge <= 1'b0;
    end else begin
      async_edge <= edge_i;
    end
  end

  // Instantiate the synchronizer
  ff_sync ff_sync_tx_to_rx (
    .clk(clk_rx_i),
    .rstn(rstn_rx_i),
    .async_in(async_edge),
    .sync_out(sync_edge)
  );

  // Detect the rising edge of the synchronized signal
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      sync_edge_d <= 1'b0;
      edge_o <= 1'b0;
    end else begin
      sync_edge_d <= sync_edge;
      edge_o <= sync_edge & ~sync_edge_d;
    end
  end

endmodule

module ff_sync (
  input  logic clk,
  input  logic rstn,
  input  logic async_in,
  output logic sync_out
);

  logic ff1;
  logic ff2;

  // Two-stage flip-flop synchronizer
  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      ff1 <= 1'b0;
      ff2 <= 1'b0;
    end else begin
      ff1 <= async_in;
      ff2 <= ff1;
    end
  end

  assign sync_out = ff2;

endmodule
