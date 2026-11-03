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
  logic src_clear_i_sync;
  logic dst_clear_i_sync;
  logic [WIDTH-1:0] data_sync;
  logic valid_sync;
  logic ready_sync;
  logic src_valid_reg;
  logic src_ready_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;

  // Synchronize clear signals across clock domains
  cdc_2phase_clearable_sync #(
    .WIDTH(WIDTH),
    .SYNC_STAGES(SYNC_STAGES),
    .CLEAR_ON_ASYNC_RESET(CLEAR_ON_ASYNC_RESET)
  ) sync_src_to_dst (
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .clear_i(src_clear_i),
    .clear_o(src_clear_i_sync)
  );

  cdc_2phase_clearable_sync #(
    .WIDTH(WIDTH),
    .SYNC_STAGES(SYNC_STAGES),
    .CLEAR_ON_ASYNC_RESET(CLEAR_ON_ASYNC_RESET)
  ) sync_dst_to_src (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .clear_i(dst_clear_i),
    .clear_o(dst_clear_i_sync)
  );

  // Source side logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 0;
      src_ready_reg <= 1;
      data_sync <= 0;
    end else if (src_clear_i_sync) begin
      src_valid_reg <= 0;
      src_ready_reg <= 1;
    end else if (src_valid_i && src_ready_o) begin
      src_valid_reg <= 1;
      src_ready_reg <= 0;
      data_sync <= src_data_i;
    end else if (dst_ready_i && valid_sync) begin
      src_ready_reg <= 1;
    end
  end

  // Destination side logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 0;
      dst_ready_reg <= 1;
    end else if (dst_clear_i_sync) begin
      dst_valid_reg <= 0;
      dst_ready_reg <= 1;
    end else if (src_valid_reg && !dst_valid_reg) begin
      dst_valid_reg <= 1;
      dst_ready_reg <= 0;
      valid_sync <= 1;
      ready_sync <= 0;
      dst_data_o <= data_sync;
    end else if (dst_ready_i && valid_sync) begin
      dst_valid_reg <= 0;
      dst_ready_reg <= 1;
      valid_sync <= 0;
      ready_sync <= 1;
    end
  end

  // Outputs
  assign src_ready_o = src_ready_reg;
  assign dst_valid_o = dst_valid_reg;
  assign src_clear_pending_o = src_clear_i_sync;
  assign dst_clear_pending_o = dst_clear_i_sync;

endmodule

module cdc_2phase_clearable_sync #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3,
  parameter CLEAR_ON_ASYNC_RESET = 1
)(
  input  clk_i,
  input  rst_ni,
  input  clear_i,
  output clear_o
);

  logic [SYNC_STAGES-1:0] sync_reg;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      sync_reg <= 0;
    end else if (clear_i && CLEAR_ON_ASYNC_RESET) begin
      sync_reg <= 0;
    end else begin
      sync_reg <= {sync_reg[SYNC_STAGES-2:0], clear_i};
    end
  end

  assign clear_o = sync_reg[SYNC_STAGES-1];

endmodule
