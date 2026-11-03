module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // Instantiate the async_pulse_sync module to handle the cross-domain synchronization
  async_pulse_sync async_pulse_sync_inst (
    .clk_i    (clk_tx_i),
    .rstn_i   (rstn_tx_i),
    .pulse_i  (edge_i),
    .clk_o    (clk_rx_i),
    .rstn_o   (rstn_rx_i),
    .pulse_o  (edge_o)
  );

endmodule

module async_pulse_sync (
  input  logic clk_i,
  input  logic rstn_i,
  input  logic pulse_i,
  input  logic clk_o,
  input  logic rstn_o,
  output logic pulse_o
);

  // Internal signals for synchronization
  logic pulse_i_reg;
  logic pulse_i_sync;
  logic pulse_i_sync_reg;
  logic pulse_o_reg;

  // Register the incoming pulse in the TX clock domain
  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
      pulse_i_reg <= 1'b0;
    end else begin
      pulse_i_reg <= pulse_i;
    end
  end

  // Synchronize the registered pulse to the RX clock domain using a two-stage flip-flop synchronizer
  always_ff @(posedge clk_o or negedge rstn_o) begin
    if (!rstn_o) begin
      pulse_i_sync     <= 1'b0;
      pulse_i_sync_reg <= 1'b0;
    end else begin
      pulse_i_sync     <= pulse_i_reg;
      pulse_i_sync_reg <= pulse_i_sync;
    end
  end

  // Detect the rising edge of the synchronized pulse in the RX clock domain to generate the output pulse
  always_ff @(posedge clk_o or negedge rstn_o) begin
    if (!rstn_o) begin
      pulse_o_reg <= 1'b0;
    end else begin
      pulse_o_reg <= pulse_i_sync_reg & ~pulse_i_sync;
    end
  end

  // Assign the output pulse
  assign pulse_o = pulse_o_reg;

endmodule
