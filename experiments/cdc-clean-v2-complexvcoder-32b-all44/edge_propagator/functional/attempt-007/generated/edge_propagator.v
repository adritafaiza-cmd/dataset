module async_ff (
  input  logic clk_i,
  input  logic rstn_i,
  input  logic d_i,
  output logic q_o
);
  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
      q_o <= 1'b0;
    end else begin
      q_o <= d_i;
    end
  end
endmodule

module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);
  logic edge_i_reg;
  logic edge_i_pulse;
  logic edge_i_sync;
  logic edge_i_sync_reg;
  logic edge_i_sync_final;
  logic edge_o_reg;
  logic edge_o_pulse;
  logic edge_o_sync;
  logic edge_o_sync_reg;

  // Detect rising edge on edge_i
  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      edge_i_reg <= 1'b0;
      edge_i_pulse <= 1'b0;
    end else begin
      edge_i_reg <= edge_i;
      edge_i_pulse <= edge_i & ~edge_i_reg;
    end
  end

  // Synchronize edge_i_pulse to clk_rx_i domain
  async_ff ff_tx_to_rx (
    .clk_i(clk_rx_i),
    .rstn_i(rstn_rx_i),
    .d_i(edge_i_pulse),
    .q_o(edge_i_sync)
  );

  // Further synchronize edge_i_sync to clk_rx_i domain
  async_ff ff_tx_to_rx_2 (
    .clk_i(clk_rx_i),
    .rstn_i(rstn_rx_i),
    .d_i(edge_i_sync),
    .q_o(edge_i_sync_final)
  );

  // Detect rising edge on synchronized edge
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      edge_o_reg <= 1'b0;
      edge_o_pulse <= 1'b0;
    end else begin
      edge_o_reg <= edge_i_sync_final;
      edge_o_pulse <= edge_i_sync_final & ~edge_o_reg;
    end
  end

  // Synchronize edge_o_pulse to clk_tx_i domain
  async_ff ff_rx_to_tx (
    .clk_i(clk_tx_i),
    .rstn_i(rstn_tx_i),
    .d_i(edge_o_pulse),
    .q_o(edge_o_sync)
  );

  // Capture synchronized edge for output
  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      edge_o_sync_reg <= 1'b0;
    end else begin
      edge_o_sync_reg <= edge_o_sync;
    end
  end

  // Final output pulse
  assign edge_o = edge_o_sync_reg;

endmodule
