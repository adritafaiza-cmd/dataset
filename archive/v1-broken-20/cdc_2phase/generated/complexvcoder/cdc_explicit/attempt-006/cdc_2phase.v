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
  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic src_ready_reg;
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic src_valid_sync;
  logic src_ready_sync;
  logic dst_valid_sync;
  logic dst_ready_sync;

  // Register the source data and valid signals in the source clock domain
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= 0;
      src_valid_reg <= 0;
      src_ready_reg <= 0;
    end else begin
      src_data_reg <= src_data_i;
      src_valid_reg <= src_valid_i;
      src_ready_reg <= dst_ready_i;
    end
  end

  // Register the destination ready signal in the source clock domain
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_reg <= 0;
    end else begin
      dst_ready_reg <= dst_ready_i;
    end
  end

  // Synchronize the source valid and ready signals to the destination clock domain
  prim_sync_flop #(
    .WIDTH(1)
  ) u_src_valid_sync (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .d_i(src_valid_reg),
    .q_o(src_valid_sync)
  );

  prim_sync_flop #(
    .WIDTH(1)
  ) u_src_ready_sync (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .d_i(src_ready_reg),
    .q_o(src_ready_sync)
  );

  // Register the source valid and ready signals in the destination clock domain
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_reg <= 0;
      src_ready_reg <= 0;
    end else begin
      src_valid_reg <= src_valid_sync;
      src_ready_reg <= src_ready_sync;
    end
  end

  // Register the destination data and valid signals in the destination clock domain
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= 0;
      dst_valid_reg <= 0;
    end else begin
      if (src_valid_sync && dst_ready_sync) begin
        dst_data_reg <= src_data_reg;
        dst_valid_reg <= 1;
      end else begin
        dst_valid_reg <= 0;
      end
    end
  end

  // Synchronize the destination valid and ready signals to the source clock domain
  prim_sync_flop #(
    .WIDTH(1)
  ) u_dst_valid_sync (
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .d_i(dst_valid_reg),
    .q_o(dst_valid_sync)
  );

  prim_sync_flop #(
    .WIDTH(1)
  ) u_dst_ready_sync (
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .d_i(dst_ready_i),
    .q_o(dst_ready_sync)
  );

  // Assert src_ready_o when a new source item can be safely accepted
  assign src_ready_o = !src_valid_reg;

  // Transfer data from source to destination on valid/ready edges
  assign dst_data_o = dst_data_reg;

endmodule
