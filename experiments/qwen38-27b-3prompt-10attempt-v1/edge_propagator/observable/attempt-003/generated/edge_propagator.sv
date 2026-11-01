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

  // TX domain: toggle a bit on each pulse
  logic toggle_tx;

  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      toggle_tx <= 1'b0;
    end else if (pulse_tx) begin
      toggle_tx <= ~toggle_tx;
    end
  end

  // Synchronize toggle_tx into RX domain
  logic [1:0] sync_toggle;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      sync_toggle <= 2'b00;
    end else begin
      sync_toggle <= {sync_toggle[0], toggle_tx};
    end
  end

  // RX domain: detect rising edge of synchronized toggle
  logic sync_toggle_d;
  logic edge_rx;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      sync_toggle_d <= 1'b0;
    end else begin
      sync_toggle_d <= sync_toggle[1];
    end
  end

  assign edge_rx = sync_toggle[1] & ~sync_toggle_d;

  // RX domain: generate a single-cycle pulse on edge_rx
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
