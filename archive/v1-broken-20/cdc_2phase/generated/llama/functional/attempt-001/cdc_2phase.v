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

  logic [WIDTH-1:0] data_reg;
  logic valid_reg;
  logic ready_reg;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
      data_reg <= '0;
      valid_reg <= 1'b0;
      ready_reg <= 1'b1;
    end else if (src_valid_i && ready_reg) begin
      data_reg <= src_data_i;
      valid_reg <= 1'b1;
      ready_reg <= 1'b0;
    end else if (~src_valid_i && ~valid_reg) begin
      ready_reg <= 1'b1;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
      dst_data_o <= '0;
      dst_valid_o <= 1'b0;
    end else if (valid_reg && dst_ready_i) begin
      dst_data_o <= data_reg;
      dst_valid_o <= 1'b1;
    end else if (~valid_reg && ~dst_ready_i) begin
      dst_valid_o <= 1'b0;
    end
  end

  assign src_ready_o = ready_reg && ~valid_reg;

endmodule
