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
  logic dst_valid_reg;
  logic dst_ready_reg;

  // Synchronize source signals to destination clock domain
  sync_reg #(.WIDTH(WIDTH)) src_sync (
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .data_i(src_data_i),
    .valid_i(src_valid_i),
    .clk_o(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .data_o(src_data_reg),
    .valid_o(src_valid_reg),
    .ready_o(src_ready_reg)
  );

  // Synchronize destination signals to source clock domain
  sync_reg #(.WIDTH(WIDTH)) dst_sync (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .data_i(dst_data_reg),
    .valid_i(dst_valid_reg),
    .clk_o(src_clk_i),
    .rst_ni(src_rst_ni),
    .data_o(dst_data_o),
    .valid_o(dst_valid_o),
    .ready_o(dst_ready_reg)
  );

  // Two-phase valid/ready channel
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 0;
    end else if (dst_valid_reg && dst_ready_i) begin
      dst_valid_reg <= 0;
    end else if (src_valid_reg) begin
      dst_valid_reg <= 1;
      dst_data_reg <= src_data_reg;
    end
  end

  // Drive source ready signal
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_reg <= 0;
    end else begin
      src_ready_reg <= !dst_valid_reg || dst_ready_i;
    end
  end

endmodule

module sync_reg #(
  parameter WIDTH = 1
)(
  input  clk_i,
  input  rst_ni,
  input  [WIDTH-1:0] data_i,
  input  valid_i,
  output clk_o,
  input  rst_ni_o,
  output [WIDTH-1:0] data_o,
  output valid_o,
  input  ready_o
);

  logic [WIDTH-1:0] data_reg;
  logic valid_reg;
  logic ready_reg;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      data_reg <= 0;
      valid_reg <= 0;
    end else begin
      data_reg <= data_i;
      valid_reg <= valid_i;
      ready_reg <= ready_o;
    end
  end

  assign data_o = data_reg;
  assign valid_o = valid_reg;

endmodule
