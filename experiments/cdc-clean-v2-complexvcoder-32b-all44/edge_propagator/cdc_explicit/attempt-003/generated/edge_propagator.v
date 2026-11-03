module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // Internal signal to hold the synchronized pulse
  logic sync_pulse;

  // Instantiate the asynchronous pulse synchronizer
  async_pulse_sync tx_to_rx_pulse_sync (
    .clk_i    (clk_tx_i),
    .rstn_i   (rstn_tx_i),
    .pulse_i  (edge_i),
    .clk_o    (clk_rx_i),
    .rstn_o   (rstn_rx_i),
    .pulse_o  (sync_pulse)
  );

  // Assign the synchronized pulse to the output
  assign edge_o = sync_pulse;

endmodule

module async_pulse_sync (
  input  logic clk_i,
  input  logic rstn_i,
  input  logic pulse_i,
  input  logic clk_o,
  input  logic rstn_o,
  output logic pulse_o
);

  // Internal signals for the two-stage synchronizer
  logic meta;
  logic sync;

  // First stage of the synchronizer
  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
      meta <= 1'b0;
    end else begin
      meta <= pulse_i;
    end
  end

  // Second stage of the synchronizer
  always_ff @(posedge clk_o or negedge rstn_o) begin
    if (!rstn_o) begin
      sync <= 1'b0;
    end else begin
      sync <= meta;
    end
  end

  // Detect the rising edge of the synchronized signal
  logic sync_d;
  always_ff @(posedge clk_o or negedge rstn_o) begin
    if (!rstn_o) begin
      sync_d <= 1'b0;
    end else begin
      sync_d <= sync;
    end
  end

  // Generate a single-cycle pulse on the rising edge of the synchronized signal
  assign pulse_o = sync & ~sync_d;

endmodule
