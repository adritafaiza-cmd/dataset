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
  logic src_valid_synced;
  logic dst_ready_synced;
  logic [WIDTH-1:0] data_sync_ff1;
  logic [WIDTH-1:0] data_sync_ff2;

  // Synchronize src_valid_i to dst_clk_i
  sync_ff src_valid_sync (
    .async_in(src_valid_i),
    .sync_clk(dst_clk_i),
    .sync_rst_n(dst_rst_ni),
    .sync_out(src_valid_synced)
  );

  // Synchronize dst_ready_i to src_clk_i
  sync_ff dst_ready_sync (
    .async_in(dst_ready_i),
    .sync_clk(src_clk_i),
    .sync_rst_n(src_rst_ni),
    .sync_out(dst_ready_synced)
  );

  // Source domain logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_o <= 1'b0;
    end else begin
      src_ready_o <= dst_ready_synced;
    end
  end

  // Destination domain logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_o <= 1'b0;
      dst_data_o  <= '0;
    end else begin
      if (src_valid_synced && !dst_valid_o) begin
        dst_valid_o <= 1'b1;
        dst_data_o  <= src_data_i;
      end else if (dst_valid_o && dst_ready_i) begin
        dst_valid_o <= 1'b0;
      end
    end
  end

endmodule

module sync_ff (
  input  async_in,
  input  sync_clk,
  input  sync_rst_n,
  output sync_out
);

  // Internal flip-flops for synchronization
  logic ff1;
  logic ff2;

  always_ff @(posedge sync_clk or negedge sync_rst_n) begin
    if (!sync_rst_n) begin
      ff1 <= 1'b0;
      ff2 <= 1'b0;
    end else begin
      ff1 <= async_in;
      ff2 <= ff1;
    end
  end

  assign sync_out = ff2;

endmodule
