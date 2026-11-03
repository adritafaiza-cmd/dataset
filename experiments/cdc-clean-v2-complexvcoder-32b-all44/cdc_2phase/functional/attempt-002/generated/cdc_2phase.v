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

  // Internal signals in source clock domain
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;

  // Internal signals in destination clock domain
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  reg [WIDTH-1:0] src_data_meta;
  reg src_valid_meta;

  // Source clock domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= '0;
      src_valid_reg <= 0;
      src_ready_o <= 1;
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1;
      end
      src_ready_o <= !src_valid_reg;
    end
  end

  // Destination clock domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= '0;
      dst_valid_reg <= 0;
      src_data_meta <= '0;
      src_valid_meta <= 0;
      dst_valid_o <= 0;
      dst_data_o <= '0;
    end else begin
      // Synchronize signals from source domain
      src_data_meta <= src_data_reg;
      src_valid_meta <= src_valid_reg;

      // Accept synchronized transfer
      if (src_valid_meta && !dst_valid_reg) begin
        dst_data_reg <= src_data_meta;
        dst_valid_reg <= 1;
      end

      // Complete destination transfer
      if (dst_valid_reg && dst_ready_i) begin
        dst_valid_reg <= 0;
      end

      // Drive outputs
      dst_valid_o <= dst_valid_reg;
      dst_data_o <= dst_valid_reg ? dst_data_reg : '0;
    end
  end

endmodule
