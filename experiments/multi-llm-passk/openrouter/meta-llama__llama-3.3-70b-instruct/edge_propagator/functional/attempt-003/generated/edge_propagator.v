module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

logic [1:0] edge_sync;
logic edge_synced;

always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
  if (!rstn_rx_i) begin
    edge_sync <= 2'b00;
  end else begin
    edge_sync <= {edge_sync[0], edge_i};
  end
end

assign edge_synced = edge_sync[1] && !edge_sync[0];

logic [1:0] edge_pulse;
logic edge_pulse_out;

always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
  if (!rstn_rx_i) begin
    edge_pulse <= 2'b00;
  end else if (edge_synced) begin
    edge_pulse <= 2'b01;
  end else if (edge_pulse == 2'b01) begin
    edge_pulse <= 2'b10;
  end else begin
    edge_pulse <= edge_pulse;
  end
end

assign edge_pulse_out = edge_pulse[0] && !edge_pulse[1];

always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
  if (!rstn_rx_i) begin
    edge_o <= 1'b0;
  end else begin
    edge_o <= edge_pulse_out;
  end
end

endmodule
