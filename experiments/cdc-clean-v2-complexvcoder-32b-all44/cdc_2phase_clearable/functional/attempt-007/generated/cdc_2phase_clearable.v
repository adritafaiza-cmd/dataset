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
  logic src_clear_synced;
  logic dst_clear_synced;
  logic src_clear_req;
  logic dst_clear_req;
  logic src_clear_ack;
  logic dst_clear_ack;
  logic src_clear_pending;
  logic dst_clear_pending;
  logic src_valid_synced;
  logic dst_ready_synced;
  logic [WIDTH-1:0] data_ff;
  logic valid_ff;
  logic ready_ff;

  // Sync clear signals
  sync_ff #(.WIDTH(1)) sync_src_clear (
    .async_in (src_clear_i),
    .sync_out (src_clear_synced),
    .clk      (dst_clk_i),
    .rst_ni   (dst_rst_ni)
  );

  sync_ff #(.WIDTH(1)) sync_dst_clear (
    .async_in (dst_clear_i),
    .sync_out (dst_clear_synced),
    .clk      (src_clk_i),
    .rst_ni   (src_rst_ni)
  );

  // Synchronize src_valid_i to dst_clk_i
  sync_ff #(.WIDTH(1)) sync_src_valid (
    .async_in (src_valid_i),
    .sync_out (src_valid_synced),
    .clk      (dst_clk_i),
    .rst_ni   (dst_rst_ni)
  );

  // Synchronize dst_ready_i to src_clk_i
  sync_ff #(.WIDTH(1)) sync_dst_ready (
    .async_in (dst_ready_i),
    .sync_out (dst_ready_synced),
    .clk      (src_clk_i),
    .rst_ni   (src_rst_ni)
  );

  // Clear request generation
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_req <= 0;
      src_clear_pending <= 0;
    end else if (src_clear_i && !src_clear_pending) begin
      src_clear_req <= 1;
      src_clear_pending <= 1;
    end else if (src_clear_ack) begin
      src_clear_req <= 0;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_req <= 0;
      dst_clear_pending <= 0;
    end else if (dst_clear_i && !dst_clear_pending) begin
      dst_clear_req <= 1;
      dst_clear_pending <= 1;
    end else if (dst_clear_ack) begin
      dst_clear_req <= 0;
    end
  end

  // Clear acknowledge generation
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_ack <= 0;
    end else if (src_clear_req) begin
      dst_clear_ack <= 1;
    end else if (dst_clear_i) begin
      dst_clear_ack <= 0;
    end
  end

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_ack <= 0;
    end else if (dst_clear_req) begin
      src_clear_ack <= 1;
    end else if (src_clear_i) begin
      src_clear_ack <= 0;
    end
  end

  // Clear pending outputs
  assign src_clear_pending_o = src_clear_pending;
  assign dst_clear_pending_o = dst_clear_pending;

  // Data transfer logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      data_ff <= 0;
      valid_ff <= 0;
    end else if (src_valid_synced && dst_ready_synced && !dst_clear_req) begin
      data_ff <= src_data_i;
      valid_ff <= 1;
    end else if (dst_ready_i) begin
      valid_ff <= 0;
    end
  end

  // Ready signal generation
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      ready_ff <= 0;
    end else if (!valid_ff || dst_ready_synced) begin
      ready_ff <= 1;
    end else begin
      ready_ff <= 0;
    end
  end

  // Output assignments
  assign dst_data_o = data_ff;
  assign dst_valid_o = valid_ff;
  assign src_ready_o = ready_ff;

endmodule

module sync_ff #(
  parameter WIDTH = 1
)(
  input  [WIDTH-1:0] async_in,
  output [WIDTH-1:0] sync_out,
  input  clk,
  input  rst_ni
);

  logic [WIDTH-1:0] ff1;
  logic [WIDTH-1:0] ff2;

  always_ff @(posedge clk or negedge rst_ni) begin
    if (!rst_ni) begin
      ff1 <= 0;
      ff2 <= 0;
    end else begin
      ff1 <= async_in;
      ff2 <= ff1;
    end
  end

  assign sync_out = ff2;

endmodule
