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
  logic [WIDTH-1:0] src_reg;
  logic src_valid_reg;
  logic dst_valid_reg;
  logic sync_reg;

  // Sync module instances
  sync_module src_to_sync_inst (
    .src_rst_ni(src_rst_ni),
    .src_clk_i(src_clk_i),
    .src_data_i(src_data_i),
    .src_valid_i(src_valid_i),
    .src_ready_o(src_ready_o),
    .dst_data_o(src_reg),
    .dst_valid_o(src_valid_reg)
  );

  sync_module sync_module_inst (
    .src_rst_ni(src_rst_ni),
    .src_clk_i(src_clk_i),
    .src_data_i(src_reg),
    .src_valid_i(src_valid_reg),
    .src_ready_o(sync_reg),
    .dst_data_o(src_reg),
    .dst_valid_o(src_valid_reg)
  );

  sync_module sync_to_dst_inst (
    .src_rst_ni(dst_rst_ni),
    .src_clk_i(dst_clk_i),
    .src_data_i(src_reg),
    .src_valid_i(src_valid_reg),
    .src_ready_o(dst_ready_i),
    .dst_data_o(dst_data_o),
    .dst_valid_o(dst_valid_o)
  );

endmodule

module sync_module (
  input  src_rst_ni,
  input  src_clk_i,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,
  input  dst_ready_i,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o
);

  logic [WIDTH-1:0] data_reg;
  logic valid_reg;
  logic ready_reg;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      data_reg <= 0;
      valid_reg <= 0;
      ready_reg <= 1;
    end else begin
      if (src_valid_i && dst_ready_i && ready_reg) begin
        data_reg <= src_data_i;
        valid_reg <= 1;
        ready_reg <= 0;
      end else if (dst_ready_i) begin
        valid_reg <= 0;
        ready_reg <= 1;
      end
    end
  end

  assign src_ready_o = ready_reg;
  assign dst_data_o = data_reg;
  assign dst_valid_o = valid_reg;

endmodule
