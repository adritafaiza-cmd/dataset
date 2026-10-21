module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // Internal state registers
  logic tx_edge_detected;
  logic rx_edge_detected;
  logic tx_edge_latched;
  logic rx_edge_latched;

  // TX Domain: Detect rising edge on edge_i
  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      tx_edge_detected <= 1'b0;
    end else begin
      tx_edge_detected <= edge_i;
    end
  end

  // TX Domain: Capture the detected edge into a latch to hold it until RX domain confirms
  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      tx_edge_latched <= 1'b0;
    end else begin
      tx_edge_latched <= tx_edge_detected;
    end
  end

  // RX Domain: Detect rising edge on tx_edge_latched (which represents the original edge)
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      rx_edge_detected <= 1'b0;
    end else begin
      rx_edge_detected <= tx_edge_latched;
    end
  end

  // RX Domain: Capture the detected edge into the output latch
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      rx_edge_latched <= 1'b0;
    end else begin
      rx_edge_latched <= rx_edge_detected;
    end
  end

  // Output assignment
  assign edge_o = rx_edge_latched;

endmodule<|im_end|>
