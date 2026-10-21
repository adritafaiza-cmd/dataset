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

  // Internal registers for source domain
  logic src_valid_reg;
  logic src_data_reg [WIDTH-1:0];
  logic src_ready_reg;

  // Internal registers for destination domain
  logic dst_valid_reg;
  logic dst_data_reg [WIDTH-1:0];
  logic dst_ready_reg;

  // Source Domain Logic
  // Capture valid and data on rising edge of src_clk_i
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
      src_data_reg <= '{default: 1'b0};
      src_ready_reg <= 1'b1;
    end else begin
      src_valid_reg <= src_valid_i;
      src_data_reg <= src_data_i;
      // Ready is asserted if we are not currently holding a valid item
      // OR if the destination has consumed the item (dst_valid_reg is low)
      src_ready_reg <= (~src_valid_reg) | dst_ready_reg;
    end
  end

  // Destination Domain Logic
  // Capture valid and data on rising edge of dst_clk_i
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
      dst_data_reg <= '{default: 1'b0};
      dst_ready_reg <= 1'b1;
    end else begin
      dst_valid_reg <= src_valid_reg;
      dst_data_reg <= src_data_reg;
      // Ready is asserted if we are not currently holding a valid item
      // OR if the source has indicated it is ready to send more
      dst_ready_reg <= (~dst_valid_reg) | src_ready_reg;
    end
  end

  // Output assignments
  assign src_ready_o = src_ready_reg;
  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o = dst_data_reg;

endmodule<|im_end|>
