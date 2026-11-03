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
  logic src_to_dst_rst_n;
  logic dst_to_src_rst_n;
  logic src_clear_pending;
  logic dst_clear_pending;
  logic src_req, src_ack;
  logic dst_req, dst_ack;

  // Instantiate async reset synchronizers
  async_reset_sync src_to_dst_reset_sync (
    .async_rst_i(src_rst_ni),
    .clk_i(dst_clk_i),
    .rst_n_o(src_to_dst_rst_n)
  );

  async_reset_sync dst_to_src_reset_sync (
    .async_rst_i(dst_rst_ni),
    .clk_i(src_clk_i),
    .rst_n_o(dst_to_src_rst_n)
  );

  // Instantiate two-phase handshake
  two_phase_handshake handshake (
    .src_clk_i(src_clk_i),
    .rst_ni(src_to_dst_rst_n),
    .src_valid_i(src_valid_i),
    .src_ready_o(src_ready_o),
    .dst_clk_i(dst_clk_i),
    .rst_ni(dst_to_src_rst_n),
    .dst_ready_i(dst_ready_i),
    .dst_valid_o(dst_valid_o)
  );

  // Instantiate data synchronizer
  async_data_sync data_sync (
    .src_clk_i(src_clk_i),
    .src_data_i(src_data_i),
    .dst_clk_i(dst_clk_i),
    .dst_data_o(dst_data_o)
  );

  // Clear pending signals
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pending <= 1'b0;
    end else if (src_clear_i) begin
      src_clear_pending <= 1'b1;
    end else if (src_ack && dst_req) begin
      src_clear_pending <= 1'b0;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pending <= 1'b0;
    end else if (dst_clear_i) begin
      dst_clear_pending <= 1'b1;
    end else if (dst_ack && src_req) begin
      dst_clear_pending <= 1'b0;
    end
  end

  // Connect clear pending outputs
  assign src_clear_pending_o = src_clear_pending;
  assign dst_clear_pending_o = dst_clear_pending;

  // Connect handshake signals
  assign src_req = handshake.src_req;
  assign src_ack = handshake.src_ack;
  assign dst_req = handshake.dst_req;
  assign dst_ack = handshake.dst_ack;

  // Clear handshake on clear request
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni || (CLEAR_ON_ASYNC_RESET && !src_to_dst_rst_n)) begin
      handshake.src_req <= 1'b0;
      handshake.src_ack <= 1'b0;
    end else if (src_clear_i) begin
      handshake.src_req <= 1'b0;
      handshake.src_ack <= 1'b0;
    end else begin
      handshake.src_req <= src_valid_i & ~handshake.src_ack;
      handshake.src_ack <= handshake.src_req & dst_ready_i;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni || (CLEAR_ON_ASYNC_RESET && !dst_to_src_rst_n)) begin
      handshake.dst_req <= 1'b0;
      handshake.dst_ack <= 1'b0;
    end else if (dst_clear_i) begin
      handshake.dst_req <= 1'b0;
      handshake.dst_ack <= 1'b0;
    end else begin
      handshake.dst_req <= dst_valid_o & ~handshake.dst_ack;
      handshake.dst_ack <= handshake.dst_req & src_ready_o;
    end
  end

endmodule

module async_reset_sync (
  input  async_rst_i,
  input  clk_i,
  output rst_n_o
);

  logic sync_stage1, sync_stage2;

  always_ff @(posedge clk_i or negedge async_rst_i) begin
    if (!async_rst_i) begin
      sync_stage1 <= 1'b0;
      sync_stage2 <= 1'b0;
    end else begin
      sync_stage1 <= 1'b1;
      sync_stage2 <= sync_stage1;
    end
  end

  assign rst_n_o = sync_stage2;

endmodule

module two_phase_handshake (
  input  src_clk_i,
  input  rst_ni,
  input  src_valid_i,
  output src_ready_o,
  input  dst_clk_i,
  input  dst_ready_i,
  output dst_valid_o
);

  logic src_req, src_ack;
  logic dst_req, dst_ack;

  // Source side handshake
  always_ff @(posedge src_clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      src_req <= 1'b0;
      src_ack <= 1'b0;
    end else begin
      src_req <= src_valid_i & ~src_ack;
      src_ack <= src_req & dst_ready_i;
    end
  end

  // Destination side handshake
  always_ff @(posedge dst_clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      dst_req <= 1'b0;
      dst_ack <= 1'b0;
    end else begin
      dst_req <= dst_valid_o & ~dst_ack;
      dst_ack <= dst_req & src_ready_o;
    end
  end

  // Connect handshake signals
  assign src_ready_o = dst_ack;
  assign dst_valid_o = src_req;

endmodule

module async_data_sync #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3
)(
  input  src_clk_i,
  input  [WIDTH-1:0] src_data_i,
  input  dst_clk_i,
  output [WIDTH-1:0] dst_data_o
);

  logic [WIDTH-1:0] sync_stage [SYNC_STAGES-1:0];

  // Source side synchronization stages
  always_ff @(posedge src_clk_i) begin
    sync_stage[0] <= src_data_i;
    for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
      sync_stage[i] <= sync_stage[i-1];
    end
  end

  // Destination side synchronization stages
  always_ff @(posedge dst_clk_i) begin
    dst_data_o <= sync_stage[SYNC_STAGES-1];
  end

endmodule
