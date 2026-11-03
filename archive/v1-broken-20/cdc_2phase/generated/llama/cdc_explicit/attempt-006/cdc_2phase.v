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
  logic src_ready_int;
  logic dst_valid_int;
  logic [WIDTH-1:0] dst_data_int;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
      src_data_reg <= '0;
      src_valid_reg <= 1'b0;
      src_ready_int <= 1'b1;
    end else if (src_valid_i && src_ready_int) begin
      src_data_reg <= src_data_i;
      src_valid_reg <= 1'b1;
      src_ready_int <= 1'b0;
    end else if (~src_valid_i && src_ready_int) begin
      src_valid_reg <= 1'b0;
    end
  end

  assign src_ready_o = src_ready_int;

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
      dst_valid_int <= 1'b0;
      dst_data_int <= '0;
    end else if (src_valid_reg && ~dst_valid_int) begin
      dst_valid_int <= 1'b1;
      dst_data_int <= src_data_reg;
    end else if (dst_ready_i && dst_valid_int) begin
      dst_valid_int <= 1'b0;
      src_ready_int <= 1'b1;
    end
  end

  assign dst_valid_o = dst_valid_int;
  assign dst_data_o = dst_data_int;

endmodule
