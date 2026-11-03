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
  logic src_valid_sync;
  logic [WIDTH-1:0] src_data_sync;
  logic src_ready;
  logic [WIDTH-1:0] dst_data;
  logic dst_valid;
  logic [WIDTH-1:0] data_reg;
  logic valid_reg;
  logic ready_sync;

  // Instance of ff_sync to synchronize src_valid_i to dst_clk_i
  ff_sync ff_sync_src_valid (
    .async_in(src_valid_i),
    .clk(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .sync_out(src_valid_sync)
  );

  // Instance of ff_sync to synchronize src_data_i to dst_clk_i
  ff_sync ff_sync_src_data (
    .async_in(src_data_i),
    .clk(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .sync_out(src_data_sync)
  );

  // Instance of ff_sync to synchronize dst_ready_i to src_clk_i
  ff_sync ff_sync_dst_ready (
    .async_in(dst_ready_i),
    .clk(src_clk_i),
    .rst_ni(src_rst_ni),
    .sync_out(ready_sync)
  );

  // Destination side logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data <= '0;
      dst_valid <= 1'b0;
    end else begin
      if (dst_valid && dst_ready_i) begin
        dst_valid <= 1'b0;
      end else if (src_valid_sync && !valid_reg) begin
        dst_data <= src_data_sync;
        dst_valid <= 1'b1;
      end
    end
  end

  // Source side logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      data_reg <= '0;
      valid_reg <= 1'b0;
      src_ready <= 1'b0;
    end else begin
      if (src_valid_i && ready_sync && !valid_reg) begin
        data_reg <= src_data_i;
        valid_reg <= 1'b1;
        src_ready <= 1'b1;
      end else if (valid_reg && dst_valid && dst_ready_i) begin
        valid_reg <= 1'b0;
        src_ready <= 1'b0;
      end else begin
        src_ready <= ready_sync && !valid_reg;
      end
    end
  end

  // Output assignments
  assign src_ready_o = src_ready;
  assign dst_data_o = dst_data;
  assign dst_valid_o = dst_valid;

endmodule

module ff_sync (
  input  async_in,
  input  clk,
  input  rst_ni,
  output sync_out
);

  // Internal flip-flops for synchronization
  logic ff1;
  logic ff2;

  // Synchronization logic
  always_ff @(posedge clk or negedge rst_ni) begin
    if (!rst_ni) begin
      ff1 <= 1'b0;
      ff2 <= 1'b0;
    end else begin
      ff1 <= async_in;
      ff2 <= ff1;
    end
  end

  // Output assignment
  assign sync_out = ff2;

endmodule
