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

  // Sync flip-flops for source clock domain
  sync_ff #(
    .WIDTH(WIDTH),
    .SYNC_STAGES(SYNC_STAGES)
  ) src_sync (
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .data_i(src_data_i),
    .valid_i(src_valid_i),
    .ready_o(src_ready_o)
  );

  // Sync flip-flops for destination clock domain
  sync_ff #(
    .WIDTH(WIDTH),
    .SYNC_STAGES(SYNC_STAGES)
  ) dst_sync (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .data_i(dst_data_o),
    .valid_i(dst_valid_o),
    .ready_o(dst_ready_i)
  );

  // Clearable channel for data transfer
  clearable_channel #(
    .WIDTH(WIDTH)
  ) channel (
    .src_data_i(src_sync.data_o),
    .src_valid_i(src_sync.valid_o),
    .src_ready_o(src_sync.ready_o),
    .dst_data_i(dst_sync.data_o),
    .dst_valid_i(dst_sync.valid_o),
    .dst_ready_o(dst_sync.ready_o),
    .src_clear_i(src_clear_i),
    .dst_clear_i(dst_clear_i),
    .src_clear_pending_o(src_clear_pending_o),
    .dst_clear_pending_o(dst_clear_pending_o)
  );

endmodule

// Sync flip-flops for clock domain crossing
module sync_ff #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3
)(
  input  clk_i,
  input  rst_ni,
  input  [WIDTH-1:0] data_i,
  input  valid_i,
  output ready_o
);

  logic [WIDTH-1:0] data_ff;
  logic valid_ff;
  logic ready_ff;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      data_ff <= {WIDTH{1'b0}};
      valid_ff <= 1'b0;
      ready_ff <= 1'b0;
    end else begin
      data_ff <= data_i;
      valid_ff <= valid_i;
      ready_ff <= ready_i;
    end
  end

  assign ready_o = ready_ff;

endmodule

// Clearable two-phase valid/ready channel
module clearable_channel #(
  parameter WIDTH = 1
)(
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,
  input  [WIDTH-1:0] dst_data_i,
  input  dst_valid_i,
  output dst_ready_o,
  input  src_clear_i,
  input  dst_clear_i,
  output src_clear_pending_o,
  output dst_clear_pending_o
);

  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic src_ready_reg;
  logic dst_data_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic src_clear_pending;
  logic dst_clear_pending;

  assign src_ready_o = src_ready_reg;
  assign dst_ready_o = dst_ready_reg;
  assign src_clear_pending_o = src_clear_pending;
  assign dst_clear_pending_o = dst_clear_pending;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni || src_clear_i) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b0;
      src_clear_pending <= 1'b0;
    end else if (src_valid_i && src_ready_reg) begin
      src_data_reg <= src_data_i;
      src_valid_reg <= 1'b1;
      src_ready_reg <= 1'b0;
      src_clear_pending <= 1'b0;
    end else if (src_valid_reg && dst_ready_reg) begin
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b1;
      src_clear_pending <= 1'b0;
    end else begin
      src_ready_reg <= 1'b1;
      src_clear_pending <= 1'b0;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni || dst_clear_i) begin
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      dst_ready_reg <= 1'b0;
      dst_clear_pending <= 1'b0;
    end else if (dst_valid_i && dst_ready_reg) begin
      dst_data_reg <= dst_data_i;
      dst_valid_reg <= 1'b1;
      dst_ready_reg <= 1'b0;
      dst_clear_pending <= 1'b0;
    end else if (dst_valid_reg && src_ready_reg) begin
      dst_valid_reg <= 1'b0;
      dst_ready_reg <= 1'b1;
      dst_clear_pending <= 1'b0;
    end else begin
      dst_ready_reg <= 1'b1;
      dst_clear_pending <= 1'b0;
    end
  end

endmodule
