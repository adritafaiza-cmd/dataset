module cdc_2phase #(
  parameter WIDTH = 1
)(
  input  logic src_rst_ni,
  input  logic src_clk_i,
  input  logic [WIDTH-1:0] src_data_i,
  input  logic src_valid_i,
  output logic src_ready_o,
  input  logic dst_rst_ni,
  input  logic dst_clk_i,
  output logic [WIDTH-1:0] dst_data_o,
  output logic dst_valid_o,
  input  logic dst_ready_i
);

  logic [WIDTH-1:0] data_reg;
  logic valid_reg;
  logic ready_reg;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_o <= 1'b1;
      ready_reg <= 1'b0;
    end else if (src_valid_i && src_ready_o) begin
      src_ready_o <= 1'b0;
      ready_reg <= 1'b1;
      data_reg <= src_data_i;
    end else if (!src_valid_i && !ready_reg) begin
      src_ready_o <= 1'b1;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_o <= 1'b0;
      dst_data_o <= '0;
    end else if (ready_reg && !dst_valid_o) begin
      dst_valid_o <= 1'b1;
      dst_data_o <= data_reg;
    end else if (dst_ready_i && dst_valid_o) begin
      dst_valid_o <= 1'b0;
      ready_reg <= 1'b0;
    end
  end

endmodule
