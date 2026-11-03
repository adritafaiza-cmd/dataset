module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // Internal signals for edge detection in TX domain
  logic edge_i_reg;
  logic edge_detected;

  // Instantiate the async_pulse_sync module
  async_pulse_sync tx_to_rx_pulse_sync (
    .clk_tx_i  (clk_tx_i),
    .rstn_tx_i (rstn_tx_i),
    .pulse_in  (edge_detected),
    .clk_rx_i  (clk_rx_i),
    .rstn_rx_i (rstn_rx_i),
    .pulse_out (edge_o)
  );

  // Edge detection logic in TX domain
  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      edge_i_reg <= 1'b0;
      edge_detected <= 1'b0;
    end else begin
      edge_i_reg <= edge_i;
      edge_detected <= edge_i & ~edge_i_reg;
    end
  end

endmodule

module async_pulse_sync (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic pulse_in,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic pulse_out
);

  // Internal signals for two-stage synchronizer
  logic meta_pulse;
  logic sync_pulse;
  logic pulse_out_reg;

  // First stage of synchronizer
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      meta_pulse <= 1'b0;
    end else begin
      meta_pulse <= pulse_in;
    end
  end

  // Second stage of synchronizer
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      sync_pulse <= 1'b0;
    end else begin
      sync_pulse <= meta_pulse;
    end
  end

  // Edge detection and pulse generation in RX domain
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      pulse_out_reg <= 1'b0;
      pulse_out <= 1'b0;
    end else begin
      pulse_out_reg <= sync_pulse;
      pulse_out <= sync_pulse & ~pulse_out_reg;
    end
  end

endmodule
