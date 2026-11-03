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
  logic [WIDTH-1:0] data_ff;
  logic valid_ff;
  logic ready_ff;

  // Instantiate synchronizers
  ff_sync src_valid_sync (
    .async_in(src_valid_i),
    .sync_out(src_valid_synced),
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni)
  );

  ff_sync dst_ready_sync (
    .async_in(dst_ready_i),
    .sync_out(dst_ready_synced),
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni)
  );

  // Source side logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_o <= 1'b1;
      data_ff <= '0;
      valid_ff <= 1'b0;
    end else begin
      src_ready_o <= 1'b0;
      if (src_valid_i && dst_ready_synced) begin
        src_ready_o <= 1'b1;
        data_ff <= src_data_i;
        valid_ff <= 1'b1;
      end else if (!src_valid_i) begin
        src_ready_o <= 1'b1;
      end
    end
  end

  // Destination side logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_o <= 1'b0;
      dst_data_o <= '0;
      valid_ff <= 1'b0;
    end else begin
      dst_valid_o <= 1'b0;
      if (dst_ready_i && valid_ff) begin
        dst_valid_o <= 1'b1;
        dst_data_o <= data_ff;
        valid_ff <= 1'b0;
      end else if (valid_ff) begin
        dst_valid_o <= 1'b1;
      end
    end
  end

endmodule

// Synchronizer module
module ff_sync (
  input  async_in,
  output sync_out,
  input  clk_i,
  input  rst_ni
);

  // Internal flip-flops
  logic ff1;
  logic ff2;

  // Synchronization logic
  always_ff @(posedge clk_i or negedge rst_ni) begin
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
