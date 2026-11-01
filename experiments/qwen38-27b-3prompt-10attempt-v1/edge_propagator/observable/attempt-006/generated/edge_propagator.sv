module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // TX side: detect rising edge of edge_i and generate a pulse
  logic edge_d1_tx;
  logic edge_pulse_tx;

  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i)
      edge_d1_tx <= 1'b0;
    else
      edge_d1_tx <= edge_i;
  end

  assign edge_pulse_tx = edge_i & ~edge_d1_tx;

  // TX side: toggle a bit on each pulse
  logic toggle_tx;

  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i)
      toggle_tx <= 1'b0;
    else if (edge_pulse_tx)
      toggle_tx <= ~toggle_tx;
  end

  // RX side: synchronize toggle_tx
  logic toggle_rx_d1, toggle_rx_d2, toggle_rx_d3;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      toggle_rx_d1 <= 1'b0;
      toggle_rx_d2 <= 1'b0;
      toggle_rx_d3 <= 1'b0;
    end
    else begin
      toggle_rx_d1 <= toggle_tx;
      toggle_rx_d2 <= toggle_rx_d1;
      toggle_rx_d3 <= toggle_rx_d2;
    end
  end

  // RX side: detect rising edge of the synchronized toggle
  logic toggle_rx_d3_d1;
  logic edge_o_int;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i)
      toggle_rx_d3_d1 <= 1'b0;
    else
      toggle_rx_d3_d1 <= toggle_rx_d3;
  end

  assign edge_o_int = toggle_rx_d3 & ~toggle_rx_d3_d1;

  // Generate a single-cycle pulse on the RX side
  logic edge_o_d1;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i)
      edge_o <= 1'b0;
    else
      edge_o <= edge_o_int;
  end

endmodule
