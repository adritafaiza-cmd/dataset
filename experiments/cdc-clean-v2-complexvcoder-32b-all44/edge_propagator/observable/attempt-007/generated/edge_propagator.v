module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // Internal signals
  logic sync_edge_o;
  logic edge_o_reg;
  logic edge_o_next;

  // Instantiate the sync_cell to synchronize edge_i from clk_tx_i to clk_rx_i
  sync_cell sync_cell_inst (
    .clk_i    (clk_tx_i),
    .rstn_i   (rstn_tx_i),
    .data_i   (edge_i),
    .clk_o    (clk_rx_i),
    .rstn_o   (rstn_rx_i),
    .sync_data_o (sync_edge_o)
  );

  // Detect the rising edge of the synchronized signal in the clk_rx_i domain
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      edge_o_reg  <= 1'b0;
      edge_o_next <= 1'b0;
    end else begin
      edge_o_reg  <= sync_edge_o;
      edge_o_next <= sync_edge_o & ~edge_o_reg;
    end
  end

  // Assign the output pulse
  assign edge_o = edge_o_next;

endmodule

module sync_cell (
  input  logic clk_i,
  input  logic rstn_i,
  input  logic data_i,
  input  logic clk_o,
  input  logic rstn_o,
  output logic sync_data_o
);

  // Internal flip-flops for synchronization
  logic ff1;
  logic ff2;

  // Synchronize data_i from clk_i domain to clk_o domain
  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
      ff1 <= 1'b0;
      ff2 <= 1'b0;
    end else begin
      ff1 <= data_i;
      ff2 <= ff1;
    end
  end

  // Output the synchronized data
  always_ff @(posedge clk_o or negedge rstn_o) begin
    if (!rstn_o) begin
      sync_data_o <= 1'b0;
    end else begin
      sync_data_o <= ff2;
    end
  end

endmodule
