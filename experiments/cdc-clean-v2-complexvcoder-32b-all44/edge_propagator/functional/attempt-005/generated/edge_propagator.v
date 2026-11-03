module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // Internal signals
  logic edge_i_reg;
  logic edge_detected;
  logic edge_detected_sync;
  logic edge_o_reg;

  // Detect rising edge of edge_i in the TX clock domain
  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      edge_i_reg <= 1'b0;
      edge_detected <= 1'b0;
    end else begin
      edge_i_reg <= edge_i;
      edge_detected <= edge_i & ~edge_i_reg;
    end
  end

  // Synchronize the detected edge to the RX clock domain
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      edge_detected_sync <= 1'b0;
      edge_o_reg <= 1'b0;
    end else begin
      edge_detected_sync <= edge_detected;
      edge_o_reg <= edge_detected_sync & ~edge_o_reg;
    end
  end

  // Assign the output
  assign edge_o = edge_o_reg;

endmodule
