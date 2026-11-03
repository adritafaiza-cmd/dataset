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
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg, src_valid_reg2;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg, dst_valid_reg2;

  // Source-domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 0;
      src_valid_reg2 <= 0;
      src_ready_o <= 1;
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1;
      end
      src_valid_reg2 <= src_valid_reg;
      src_ready_o <= ~src_valid_reg;
    end
  end

  // Destination-domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= 0;
      dst_valid_reg <= 0;
      dst_valid_reg2 <= 0;
    end else begin
      if (src_valid_reg2 && !dst_valid_reg) begin
        dst_data_reg <= src_data_reg;
        dst_valid_reg <= 1;
      end
      if (dst_valid_reg && dst_ready_i) begin
        dst_valid_reg <= 0;
      end
      dst_valid_reg2 <= dst_valid_reg;
    end
  end

  // Output assignments
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
