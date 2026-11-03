module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // Internal signals
  logic edge_i_synced;
  logic edge_i_ff1;
  logic edge_i_ff2;

  // Synchronize edge_i to clk_rx_i domain
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      edge_i_ff1 <= 0;
      edge_i_ff2 <= 0;
    end else begin
      edge_i_ff1 <= edge_i_synced;
      edge_i_ff2 <= edge_i_ff1;
    end
  end

  // Detect edge in the rx domain
  logic edge_o_ff1;
  logic edge_o_ff2;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      edge_o_ff1 <= 0;
      edge_o_ff2 <= 0;
    end else begin
      edge_o_ff1 <= edge_i_ff2;
      edge_o_ff2 <= edge_o_ff1;
    end
  end

  assign edge_o = edge_o_ff2 & ~edge_o_ff1;

  // Synchronize edge_i to clk_tx_i domain
  logic edge_i_sync_ff1;
  logic edge_i_sync_ff2;

  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      edge_i_sync_ff1 <= 0;
      edge_i_sync_ff2 <= 0;
    end else begin
      edge_i_sync_ff1 <= edge_i;
      edge_i_sync_ff2 <= edge_i_sync_ff1;
    end
  end

  assign edge_i_synced = edge_i_sync_ff2 & ~edge_i_sync_ff1;

endmodule
