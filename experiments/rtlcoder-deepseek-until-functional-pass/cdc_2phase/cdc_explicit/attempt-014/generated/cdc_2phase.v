module cdc_2phase #(
  parameter WIDTH = 1
)(
  input                  src_rst_ni,
  input                  src_clk_i,
  input      [WIDTH-1:0] src_data_i,
  input                  src_valid_i,
  output                 src_ready_o,

  input                  dst_rst_ni,
  input                  dst_clk_i,
  output     [WIDTH-1:0] dst_data_o,
  output                 dst_valid_o,
  input                  dst_ready_i
);

  reg [WIDTH-1:0] data_reg;
  reg valid_reg;
  wire ready_wire;

  assign src_ready_o = ready_wire;
  assign dst_data_o = data_reg;
  assign dst_valid_o = valid_reg;

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      valid_reg <= 0;
    end else if (src_valid_i && ready_wire) begin
      valid_reg <= 1;
      data_reg <= src_data_i;
    end else if (dst_ready_i && valid_reg) begin
      valid_reg <= 0;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      ready_wire <= 0;
    end else if (dst_ready_i && valid_reg) begin
      ready_wire <= 1;
    end else if (!dst_ready_i && valid_reg) begin
      ready_wire <= 0;
    end
  end


endmodule
