module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // TX domain: detect rising edge of edge_i and toggle a level signal
  logic edge_i_d1;
  logic edge_i_d2;
  logic tx_edge_detected;
  logic toggle_tx;

  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      edge_i_d1 <= 1'b0;
      edge_i_d2 <= 1'b0;
      toggle_tx <= 1'b0;
    end else begin
      edge_i_d1 <= edge_i;
      edge_i_d2 <= edge_i_d1;
      if (edge_i_d1 && !edge_i_d2) begin
        toggle_tx <= ~toggle_tx;
      end
    end
  end

  // Synchronize toggle_tx into RX domain
  logic toggle_rx_d1;
  logic toggle_rx_d2;
  logic toggle_rx_d3;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      toggle_rx_d1 <= 1'b0;
      toggle_rx_d2 <= 1'b0;
      toggle_rx_d3 <= 1'b0;
    end else begin
      toggle_rx_d1 <= toggle_tx;
      toggle_rx_d2 <= toggle_rx_d1;
      toggle_rx_d3 <= toggle_rx_d2;
    end
  end

  // RX domain: detect edge on synchronized toggle and generate pulse
  logic toggle_rx_d3_d1;
  logic toggle_rx_d3_d2;
  logic rx_edge_detected;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      toggle_rx_d3_d1 <= 1'b0;
      toggle_rx_d3_d2 <= 1'b0;
    end else begin
      toggle_rx_d3_d1 <= toggle_rx_d3;
      toggle_rx_d3_d2 <= toggle_rx_d3_d1;
    end
  end

  assign rx_edge_detected = toggle_rx_d3 ^ toggle_rx_d3_d1;

  // Generate one-cycle pulse on edge_o
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      edge_o <= 1'b0;
    end else begin
      edge_o <= rx_edge_detected;
    end
  end

endmodule
