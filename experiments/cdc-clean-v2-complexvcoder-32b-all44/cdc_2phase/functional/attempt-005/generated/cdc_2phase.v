module cdc_2phase #(
  parameter WIDTH = 1
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,
  input  dst_rst_ni,
  input  dst_clk_i,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);

  // Internal signals
  reg [WIDTH-1:0] src_data_synced;
  reg src_valid_synced, dst_valid_synced;
  reg src_ready, dst_valid;

  // Synchronizers for valid signals
  sync_cell sync_src_valid (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .d_i(src_valid_i),
    .q_o(src_valid_synced)
  );

  sync_cell sync_dst_valid (
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .d_i(dst_valid_o),
    .q_o(dst_valid_synced)
  );

  // Source-side logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready <= 1'b0;
      src_data_synced <= '0;
      dst_valid_synced <= 1'b0;
    end else begin
      // Accept new data if ready and valid
      if (src_valid_i && src_ready) begin
        src_data_synced <= src_data_i;
        dst_valid_synced <= 1'b1;
      end
      // Clear dst_valid_synced once it's been acknowledged by the destination
      if (dst_valid_synced && dst_ready_i) begin
        dst_valid_synced <= 1'b0;
      end
      // Set src_ready based on whether we can accept new data
      src_ready <= !dst_valid_synced;
    end
  end

  // Destination-side logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid <= 1'b0;
      dst_data_o <= '0;
    end else begin
      // Accept new data from source
      if (src_valid_synced && !dst_valid) begin
        dst_data_o <= src_data_synced;
        dst_valid <= 1'b1;
      end
      // Clear dst_valid once it's been acknowledged by the destination
      if (dst_valid && dst_ready_i) begin
        dst_valid <= 1'b0;
      end
    end
  end

  // Outputs
  assign src_ready_o = src_ready;
  assign dst_valid_o = dst_valid;

endmodule

// Synchronizer cell module
module sync_cell (
  input  clk_i,
  input  rst_ni,
  input  d_i,
  output reg q_o
);

  reg d_sync1, d_sync2;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      d_sync1 <= 1'b0;
      d_sync2 <= 1'b0;
      q_o <= 1'b0;
    end else begin
      d_sync1 <= d_i;
      d_sync2 <= d_sync1;
      q_o <= d_sync2;
    end
  end

endmodule
