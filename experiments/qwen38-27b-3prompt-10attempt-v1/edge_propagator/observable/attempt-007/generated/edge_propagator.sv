module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // TX domain: detect rising edge of edge_i and generate a pulse
  logic edge_tx_d;
  logic pulse_tx;

  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      edge_tx_d <= 1'b0;
    end else begin
      edge_tx_d <= edge_i;
    end
  end

  assign pulse_tx = edge_i & ~edge_tx_d;

  // TX domain: generate a toggle signal on each pulse
  logic toggle_tx;

  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      toggle_tx <= 1'b0;
    end else if (pulse_tx) begin
      toggle_tx <= ~toggle_tx;
    end
  end

  // RX domain: synchronize toggle_tx
  logic toggle_rx_1, toggle_rx_2, toggle_rx_3;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      toggle_rx_1 <= 1'b0;
      toggle_rx_2 <= 1'b0;
      toggle_rx_3 <= 1'b0;
    end else begin
      toggle_rx_1 <= toggle_tx;
      toggle_rx_2 <= toggle_rx_1;
      toggle_rx_3 <= toggle_rx_2;
    end
  end

  // RX domain: detect rising edge of synchronized toggle to generate output pulse
  logic toggle_rx_3_d;
  logic edge_rx;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      toggle_rx_3_d <= 1'b0;
    end else begin
      toggle_rx_3_d <= toggle_rx_3;
    end
  end

  assign edge_rx = toggle_rx_3 & ~toggle_rx_3_d;

  // RX domain: generate a one-cycle pulse on edge_rx
  logic edge_o_d;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      edge_o_d <= 1'b0;
    end else begin
      edge_o_d <= edge_rx;
    end
  end

  assign edge_o = edge_rx;

endmodule
