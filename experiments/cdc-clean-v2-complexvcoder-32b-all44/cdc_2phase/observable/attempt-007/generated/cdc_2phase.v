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

  // Internal signals for synchronization and storage
  logic src_valid_synced;
  logic [WIDTH-1:0] src_data_synced;
  logic dst_ready_synced;
  logic valid_reg;
  logic [WIDTH-1:0] data_reg;
  logic ready_synced;

  // Instantiate ff_sync for synchronizing src_valid_i to dst_clk_i
  ff_sync ff_sync_src_valid (
    .async_in(src_valid_i),
    .sync_out(src_valid_synced),
    .clk(dst_clk_i),
    .rst_ni(dst_rst_ni)
  );

  // Instantiate ff_sync for synchronizing src_data_i to dst_clk_i
  ff_sync ff_sync_src_data (
    .async_in(src_data_i),
    .sync_out(src_data_synced),
    .clk(dst_clk_i),
    .rst_ni(dst_rst_ni)
  );

  // Instantiate ff_sync for synchronizing dst_ready_i to src_clk_i
  ff_sync ff_sync_dst_ready (
    .async_in(dst_ready_i),
    .sync_out(dst_ready_synced),
    .clk(src_clk_i),
    .rst_ni(src_rst_ni)
  );

  // Register valid and data signals in the destination clock domain
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      valid_reg <= 0;
      data_reg <= 0;
    end else if (src_valid_synced && !valid_reg) begin
      valid_reg <= 1;
      data_reg <= src_data_synced;
    end else if (dst_ready_i && valid_reg) begin
      valid_reg <= 0;
    end
  end

  // Drive dst outputs from the registered data and valid signals
  assign dst_data_o = data_reg;
  assign dst_valid_o = valid_reg;

  // Drive src_ready_o from the synchronized dst_ready_i
  assign src_ready_o = dst_ready_synced && !valid_reg;

endmodule

// Two-stage flip-flop synchronizer module
module ff_sync (
  input  async_in,
  output sync_out,
  input  clk,
  input  rst_ni
);

  logic ff1;
  logic ff2;

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
