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

  // Internal signals
  wire handshake_src_to_dst_valid;
  wire handshake_src_to_dst_ready;
  wire handshake_dst_to_src_valid;
  wire handshake_dst_to_src_ready;
  wire clear_src_to_dst_signal;
  wire clear_dst_to_src_signal;

  // Reset synchronizers
  async_reset_synchronizer #(.SYNC_STAGES(SYNC_STAGES)) src_reset_sync (
    .async_reset_i(src_rst_ni),
    .clk_i(dst_clk_i),
    .sync_reset_o(dst_rst_ni_synced)
  );

  async_reset_synchronizer #(.SYNC_STAGES(SYNC_STAGES)) dst_reset_sync (
    .async_reset_i(dst_rst_ni),
    .clk_i(src_clk_i),
    .sync_reset_o(src_rst_ni_synced)
  );

  // Handshake modules
  async_handshake handshake_src_to_dst (
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .valid_i(src_valid_i),
    .ready_o(src_ready_o),
    .valid_o(handshake_src_to_dst_valid),
    .ready_i(handshake_src_to_dst_ready)
  );

  async_handshake handshake_dst_to_src (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .valid_i(handshake_dst_to_src_valid),
    .ready_o(handshake_dst_to_src_ready),
    .valid_o(dst_ready_i),
    .ready_i(dst_valid_o)
  );

  // Clear signal synchronizers
  async_clear clear_src_to_dst (
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .clear_i(src_clear_i),
    .clear_o(clear_src_to_dst_signal)
  );

  async_clear clear_dst_to_src (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .clear_i(dst_clear_i),
    .clear_o(clear_dst_to_src_signal)
  );

  // Data synchronization
  reg [WIDTH-1:0] src_data_synced;
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_synced <= 0;
    end else if (handshake_src_to_dst_valid && handshake_src_to_dst_ready) begin
      src_data_synced <= src_data_i;
    end
  end

  // Output assignments
  assign dst_data_o = src_data_synced;
  assign dst_valid_o = handshake_src_to_dst_valid;
  assign src_clear_pending_o = clear_src_to_dst_signal;
  assign dst_clear_pending_o = clear_dst_to_src_signal;

endmodule

module async_reset_synchronizer #(
  parameter SYNC_STAGES = 3
)(
  input  async_reset_i,
  input  clk_i,
  output sync_reset_o
);

  reg [SYNC_STAGES-1:0] sync_stage;

  always @(posedge clk_i) begin
    sync_stage[0] <= async_reset_i;
    for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
      sync_stage[i] <= sync_stage[i-1];
    end
  end

  assign sync_reset_o = sync_stage[SYNC_STAGES-1];

endmodule

module async_handshake (
  input  clk_i,
  input  rst_ni,
  input  valid_i,
  output ready_o,
  output valid_o,
  input  ready_i
);

  reg valid_synced;

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      valid_synced <= 0;
    end else begin
      valid_synced <= valid_i;
    end
  end

  assign valid_o = valid_synced;
  assign ready_o = ready_i;

endmodule

module async_clear (
  input  clk_i,
  input  rst_ni,
  input  clear_i,
  output clear_o
);

  reg clear_synced;

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      clear_synced <= 0;
    end else begin
      clear_synced <= clear_i;
    end
  end

  assign clear_o = clear_synced;

endmodule
