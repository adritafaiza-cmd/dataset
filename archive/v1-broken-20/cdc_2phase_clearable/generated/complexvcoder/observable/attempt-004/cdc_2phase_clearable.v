module cdc_2phase_clearable #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3,
  parameter CLEAR_ON_ASYNC_RESET = 1
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  src_clear_i,
  output src_clear_pending_o,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,
  input  dst_rst_ni,
  input  dst_clk_i,
  input  dst_clear_i,
  output dst_clear_pending_o,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);

  // Synchronization modules
  logic [WIDTH-1:0] src_sync_data;
  logic src_sync_valid;
  logic src_sync_ready;

  logic [WIDTH-1:0] dst_sync_data;
  logic dst_sync_valid;
  logic dst_sync_ready;

  sync #(
    .WIDTH(WIDTH),
    .SYNC_STAGES(SYNC_STAGES)
  ) src_sync (
    .clk(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .data_i(src_data_i),
    .valid_i(src_valid_i),
    .ready_o(src_sync_ready),
    .data_o(src_sync_data),
    .valid_o(src_sync_valid)
  );

  sync #(
    .WIDTH(WIDTH),
    .SYNC_STAGES(SYNC_STAGES)
  ) dst_sync (
    .clk(src_clk_i),
    .rst_ni(src_rst_ni),
    .data_i(dst_data_o),
    .valid_i(dst_valid_o),
    .ready_o(dst_sync_ready),
    .data_o(dst_sync_data),
    .valid_o(dst_sync_valid)
  );

  // Buffer modules
  logic [WIDTH-1:0] src_buffer_data;
  logic src_buffer_valid;
  logic src_buffer_ready;

  logic [WIDTH-1:0] dst_buffer_data;
  logic dst_buffer_valid;
  logic dst_buffer_ready;

  buffer #(
    .WIDTH(WIDTH)
  ) src_buffer (
    .clk(src_clk_i),
    .rst_ni(src_rst_ni),
    .data_i(src_sync_data),
    .valid_i(src_sync_valid),
    .ready_o(src_buffer_ready)
  );

  buffer #(
    .WIDTH(WIDTH)
  ) dst_buffer (
    .clk(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .data_i(dst_sync_data),
    .valid_i(dst_sync_valid),
    .ready_o(dst_buffer_ready)
  );

  // Clear flag modules
  logic src_clear_flag_clear_pending;
  logic dst_clear_flag_clear_pending;

  clear_flag #(
    .WIDTH(1)
  ) src_clear_flag (
    .clk(src_clk_i),
    .rst_ni(src_rst_ni),
    .clear_i(src_clear_i),
    .clear_pending_o(src_clear_flag_clear_pending)
  );

  clear_flag #(
    .WIDTH(1)
  ) dst_clear_flag (
    .clk(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .clear_i(dst_clear_i),
    .clear_pending_o(dst_clear_flag_clear_pending)
  );

  // Connections
  assign src_sync_ready = src_buffer_ready;
  assign dst_sync_ready = dst_buffer_ready;
  assign dst_clear_flag_clear_i = src_clear_flag_clear_pending;
  assign src_clear_flag_clear_i = dst_clear_flag_clear_pending;

  // Output logic
  assign src_ready_o = src_buffer_ready;
  assign dst_valid_o = dst_buffer_valid;
  assign dst_data_o = dst_buffer_data;

  // Clear pending outputs
  assign src_clear_pending_o = src_clear_flag_clear_pending;
  assign dst_clear_pending_o = dst_clear_flag_clear_pending;

endmodule
