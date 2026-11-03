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
  logic edge_rx_to_tx;
  logic edge_detect;
  logic edge_ff;

  // Synchronize edge_i from clk_tx_i to clk_rx_i domain
  ff_sync ff_sync_tx_to_rx (
    .clk_i(clk_tx_i),
    .rstn_i(rstn_tx_i),
    .data_i(edge_i),
    .clk_o(clk_rx_i),
    .rstn_o(rstn_rx_i),
    .data_o(edge_tx_to_rx)
  );

  // Synchronize edge_o from clk_rx_i to clk_tx_i domain
  ff_sync ff_sync_rx_to_tx (
    .clk_i(clk_rx_i),
    .rstn_i(rstn_rx_i),
    .data_i(edge_o),
    .clk_o(clk_tx_i),
    .rstn_o(rstn_tx_i),
    .data_o(edge_rx_to_tx)
  );

  // Detect rising edge of edge_tx_to_rx
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      edge_detect <= 1'b0;
    end else begin
      edge_detect <= edge_tx_to_rx & ~edge_rx_to_tx;
    end
  end

  // Generate edge_o pulse
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      edge_ff <= 1'b0;
      edge_o  <= 1'b0;
    end else begin
      edge_ff <= edge_detect;
      edge_o  <= edge_ff & ~edge_detect;
    end
  end

endmodule

module ff_sync (
  input  logic clk_i,
  input  logic rstn_i,
  input  logic data_i,
  input  logic clk_o,
  input  logic rstn_o,
  output logic data_o
);

  // Internal flip-flops for synchronization
  logic ff1;
  logic ff2;

  // First stage of synchronization
  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
      ff1 <= 1'b0;
    end else begin
      ff1 <= data_i;
    end
  end

  // Second stage of synchronization
  always_ff @(posedge clk_o or negedge rstn_o) begin
    if (!rstn_o) begin
      ff2 <= 1'b0;
      data_o <= 1'b0;
    end else begin
      ff2 <= ff1;
      data_o <= ff2;
    end
  end

endmodule
