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
  logic [WIDTH-1:0] synced_data_i;
  logic synced_valid_i;
  logic [WIDTH-1:0] synced_data_o;
  logic synced_valid_o;
  logic src_ready_ff_q;
  logic dst_valid_ff_q;

  // Synchronizer for src_data_i and src_valid_i
  sync_reg #(.WIDTH(WIDTH)) src_sync (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .data_in(src_data_i),
    .valid_in(src_valid_i),
    .ready_in(dst_ready_i),
    .data_out(synced_data_i),
    .valid_out(synced_valid_i)
  );

  // Synchronizer for dst_data_o and dst_valid_o
  sync_reg #(.WIDTH(WIDTH)) dst_sync (
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .data_in(dst_data_o),
    .valid_in(dst_valid_o),
    .ready_in(src_ready_o),
    .data_out(synced_data_o),
    .valid_out(synced_valid_o)
  );

  // FF to hold src_ready_o for one clock cycle
  ff src_ready_ff (
    .clk(src_clk_i),
    .rst_n(src_rst_ni),
    .d(src_ready_o),
    .q(src_ready_ff_q)
  );

  // FF to hold dst_valid_o for one clock cycle
  ff dst_valid_ff (
    .clk(dst_clk_i),
    .rst_n(dst_rst_ni),
    .d(dst_valid_o),
    .q(dst_valid_ff_q)
  );

  // Assign outputs
  assign src_ready_o = src_ready_ff_q;
  assign dst_data_o = synced_data_o;
  assign dst_valid_o = dst_valid_ff_q;

endmodule
