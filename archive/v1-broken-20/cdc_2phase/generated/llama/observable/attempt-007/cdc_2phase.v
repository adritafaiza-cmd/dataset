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

  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic src_ready_reg;
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_reg;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= '0;
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b0;
    end else begin
      if (src_valid_i && src_ready_reg) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1'b1;
      end else if (!src_valid_i) begin
        src_valid_reg <= 1'b0;
      end
      src_ready_reg <= !src_valid_reg || dst_valid_reg;
    end
  end

  logic [WIDTH-1:0] src_data_gray;
  logic src_valid_gray;
  logic [WIDTH-1:0] src_data_gray_sync;
  logic src_valid_gray_sync;

  gray_encode #(.WIDTH(WIDTH)) gray_encode_inst (
    .data_i(src_data_reg),
    .data_o(src_data_gray)
  );

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_gray <= 1'b0;
    end else begin
      src_valid_gray <= src_valid_reg;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_data_gray_sync <= '0;
      src_valid_gray_sync <= 1'b0;
    end else begin
      src_data_gray_sync <= src_data_gray;
      src_valid_gray_sync <= src_valid_gray;
    end
  end

  logic [WIDTH-1:0] dst_data_gray_sync;
  logic dst_valid_gray_sync;

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_gray_sync <= '0;
      dst_valid_gray_sync <= 1'b0;
    end else begin
      if (dst_ready_i && dst_valid_reg) begin
        dst_data_gray_sync <= src_data_gray_sync;
        dst_valid_gray_sync <= src_valid_gray_sync;
      end else if (!dst_ready_i) begin
        dst_valid_gray_sync <= 1'b0;
      end
    end
  end

  gray_decode #(.WIDTH(WIDTH)) gray_decode_inst (
    .data_i(dst_data_gray_sync),
    .data_o(dst_data_reg)
  );

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
    end else begin
      dst_valid_reg <= dst_valid_gray_sync;
    end
  end

  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;
  assign src_ready_o = !src_valid_reg || dst_valid_reg;

endmodule

module gray_encode #(
  parameter WIDTH = 1
)(
  input  [WIDTH-1:0] data_i,
  output [WIDTH-1:0] data_o
);

  assign data_o = (data_i >> 1) ^ data_i;

endmodule

module gray_decode #(
  parameter WIDTH = 1
)(
  input  [WIDTH-1:0] data_i,
  output [WIDTH-1:0] data_o
);

  logic [WIDTH-1:0] data_gray;
  assign data_gray = data_i;
  always_comb begin
    data_o = data_gray;
    for (int i = 1; i < WIDTH; i++) begin
      data_o[i] ^= data_o[i-1];
    end
  end

endmodule
