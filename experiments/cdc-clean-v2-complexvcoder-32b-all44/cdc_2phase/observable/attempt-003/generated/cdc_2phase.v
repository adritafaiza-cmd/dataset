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
  reg [WIDTH-1:0] data_reg;
  reg valid_reg;
  reg src_ready;
  reg dst_valid;
  reg sync_src_valid;
  reg [WIDTH-1:0] sync_src_data;

  // Instantiate the ff_sync module for src_valid_i
  ff_sync #(
    .WIDTH(1)
  ) ff_sync_src_valid (
    .async_in(src_valid_i),
    .clk(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .sync_out(sync_src_valid)
  );

  // Instantiate the ff_sync module for src_data_i
  ff_sync #(
    .WIDTH(WIDTH)
  ) ff_sync_src_data (
    .async_in(src_data_i),
    .clk(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .sync_out(sync_src_data)
  );

  // Source side logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready <= 0;
    end else begin
      src_ready <= !valid_reg;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      data_reg <= 0;
      valid_reg <= 0;
    end else if (src_valid_i && src_ready) begin
      data_reg <= src_data_i;
      valid_reg <= 1;
    end
  end

  assign src_ready_o = src_ready;

  // Destination side logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid <= 0;
      dst_data_o <= 0;
    end else if (sync_src_valid && !valid_reg) begin
      data_reg <= sync_src_data;
      valid_reg <= 1;
    end else if (dst_ready_i && valid_reg) begin
      valid_reg <= 0;
    end
  end

  assign dst_data_o = data_reg;
  assign dst_valid_o = valid_reg;

endmodule

module ff_sync #(
  parameter WIDTH = 1
)(
  input  [WIDTH-1:0] async_in,
  input  clk,
  input  rst_ni,
  output [WIDTH-1:0] sync_out
);

  reg [WIDTH-1:0] ff1;
  reg [WIDTH-1:0] ff2;

  always @(posedge clk or negedge rst_ni) begin
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
