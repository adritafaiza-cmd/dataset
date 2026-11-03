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
  logic [WIDTH-1:0] src_to_dst_reg;
  logic src_valid_reg;
  logic src_ready_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;

  // Register to hold data from source clock domain
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_to_dst_reg <= 0;
      src_valid_reg <= 0;
      src_ready_reg <= 1;
    end else begin
      if (src_valid_i && src_ready_reg && dst_ready_i) begin
        src_to_dst_reg <= src_data_i;
        src_valid_reg <= 1;
      end else if (dst_valid_reg && dst_ready_i) begin
        src_valid_reg <= 0;
      end
      src_ready_reg <= ~src_valid_reg;
    end
  end

  // Register to hold data from destination clock domain
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o <= 0;
      dst_valid_o <= 0;
      dst_ready_reg <= 1;
    end else begin
      if (src_valid_reg && dst_ready_reg) begin
        dst_data_o <= src_to_dst_reg;
        dst_valid_o <= 1;
      end else if (dst_valid_o && dst_ready_i) begin
        dst_valid_o <= 0;
      end
      dst_ready_reg <= ~dst_valid_o;
    end
  end

  // Assign outputs
  assign src_ready_o = src_ready_reg;
  assign dst_ready_reg = dst_ready_i;

endmodule
