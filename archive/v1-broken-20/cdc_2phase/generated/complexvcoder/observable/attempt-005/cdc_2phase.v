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

  // Internal signals for clock domain crossing
  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic src_ready_reg;
  logic dst_data_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;

  // Register the source data and valid signals on the source clock domain
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b0;
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= src_valid_i;
        src_ready_reg <= src_ready_o;
      end
    end
  end

  // Register the destination data and valid signals on the destination clock domain
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      dst_ready_reg <= 1'b0;
    end else begin
      if (dst_valid_i && dst_ready_i) begin
        dst_data_reg <= src_data_reg;
        dst_valid_reg <= src_valid_reg;
        dst_ready_reg <= dst_ready_i;
      end
    end
  end

  // Drive the outputs
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;
  assign src_ready_o = dst_ready_reg;

endmodule
