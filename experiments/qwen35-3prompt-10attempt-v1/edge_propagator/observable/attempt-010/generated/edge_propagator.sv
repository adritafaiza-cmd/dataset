```systemverilog
module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // Synchronizer chain for the input event from tx domain to rx domain
  // Using a 2-stage synchronizer to filter out metastability
  logic sync_edge_1;
  logic sync_edge_2;

  // Synchronize edge_i from clk_tx_i to clk_rx_i
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      sync_edge_1 <= 1'b0;
    end else begin
      sync_edge_1 <= edge_i;
    end
  end

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      sync_edge_2 <= 1'b0;
    end else begin
      sync_edge_2 <= sync_edge_1;
    end
  end

  // Edge detection in the rx domain
  // We detect the transition from 0 to 1 on the synchronized signal
  logic prev_sync_edge;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      prev_sync_edge <= 1'b0;
      edge_o <= 1'b0;
    end else begin
      prev_sync_edge <= sync_edge_2;
      if (sync_edge_2 && !prev_sync_edge) begin
        edge_o <= 1'b1;
      end else begin
        edge_o <= 1'b0;
      end
    end
  end

endmodule
```<|im_end|>
