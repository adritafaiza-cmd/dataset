module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // Internal signals
  logic sync_edge_i;
  logic edge_detected_tx;

  // Edge detector in TX domain
  edge_detector edge_detector_tx (
    .clk(clk_tx_i),
    .rstn(rstn_tx_i),
    .din(edge_i),
    .edge(edge_detected_tx)
  );

  // Synchronize the detected edge to RX domain
  ff_sync ff_sync_tx_to_rx (
    .clk_src(clk_tx_i),
    .rstn_src(rstn_tx_i),
    .din(edge_detected_tx),
    .clk_dst(clk_rx_i),
    .rstn_dst(rstn_rx_i),
    .dout(sync_edge_i)
  );

  // Pulse generator in RX domain
  pulse_generator pulse_generator_rx (
    .clk(clk_rx_i),
    .rstn(rstn_rx_i),
    .din(sync_edge_i),
    .pulse(edge_o)
  );

endmodule

module ff_sync (
  input  logic clk_src,
  input  logic rstn_src,
  input  logic din,
  input  logic clk_dst,
  input  logic rstn_dst,
  output logic dout
);

  // Internal signals
  logic ff1, ff2;

  // Synchronize din from clk_src to clk_dst using two flip-flops
  always_ff @(posedge clk_src or negedge rstn_src) begin
    if (!rstn_src) begin
      ff1 <= 1'b0;
      ff2 <= 1'b0;
    end else begin
      ff1 <= din;
      ff2 <= ff1;
    end
  end

  // Output synchronized signal
  always_ff @(posedge clk_dst or negedge rstn_dst) begin
    if (!rstn_dst) begin
      dout <= 1'b0;
    end else begin
      dout <= ff2;
    end
  end

endmodule

module edge_detector (
  input  logic clk,
  input  logic rstn,
  input  logic din,
  output logic edge
);

  // Internal signal
  logic din_ff;

  // Detect rising edge on din
  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      din_ff <= 1'b0;
      edge <= 1'b0;
    end else begin
      din_ff <= din;
      edge <= din & ~din_ff;
    end
  end

endmodule

module pulse_generator (
  input  logic clk,
  input  logic rstn,
  input  logic din,
  output logic pulse
);

  // Internal signal
  logic din_ff;

  // Generate a single pulse on din transition from low to high
  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      din_ff <= 1'b0;
      pulse <= 1'b0;
    end else begin
      din_ff <= din;
      pulse <= din & ~din_ff;
    end
  end

endmodule
