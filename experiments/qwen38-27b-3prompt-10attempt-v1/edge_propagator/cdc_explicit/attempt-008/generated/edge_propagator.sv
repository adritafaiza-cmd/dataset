module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // TX domain: detect rising edge of edge_i and generate a toggle
  logic edge_i_d;
  logic edge_detected;
  logic toggle_tx;

  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      edge_i_d    <= 1'b0;
      toggle_tx   <= 1'b0;
    end else begin
      edge_i_d    <= edge_i;
      edge_detected <= edge_i & ~edge_i_d;
      if (edge_i & ~edge_i_d)
        toggle_tx <= ~toggle_tx;
    end
  end

  // Synchronize toggle_tx into RX domain
  logic toggle_rx_1;
  logic toggle_rx_2;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      toggle_rx_1 <= 1'b0;
      toggle_rx_2 <= 1'b0;
    end else begin
      toggle_rx_1 <= toggle_tx;
      toggle_rx_2 <= toggle_rx_1;
    end
  end

  // RX domain: detect toggle change and generate pulse
  logic toggle_rx_2_d;
  logic toggle_changed;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      toggle_rx_2_d <= 1'b0;
    end else begin
      toggle_rx_2_d <= toggle_rx_2;
    end
  end

  assign toggle_changed = toggle_rx_2 ^ toggle_rx_2_d;

  assign edge_o = toggle_changed;

endmodule
