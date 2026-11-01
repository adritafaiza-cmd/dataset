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
  logic edge_detected_tx;
  logic toggle_tx;

  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      edge_i_d <= 1'b0;
      toggle_tx <= 1'b0;
    end else begin
      edge_i_d <= edge_i;
      if (edge_i && !edge_i_d) begin
        toggle_tx <= ~toggle_tx;
      end
    end
  end

  // Synchronize toggle_tx to RX domain
  logic toggle_rx_1;
  logic toggle_rx_2;
  logic toggle_rx_3;

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

  // Detect rising edge of synchronized toggle in RX domain
  logic edge_o;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      edge_o <= 1'b0;
    end else begin
      edge_o <= toggle_rx_2 ^ toggle_rx_3;
    end
  end

endmodule
