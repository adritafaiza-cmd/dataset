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
  reg [WIDTH-1:0] src_reg_data;
  reg src_reg_valid;
  reg dst_reg_valid;
  reg [WIDTH-1:0] dst_reg_data;
  reg dst_reg_valid_sync;

  // Source-side logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_reg_valid <= 0;
      src_reg_data <= 0;
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_reg_valid <= 1;
        src_reg_data <= src_data_i;
      end else if (dst_reg_valid_sync) begin
        src_reg_valid <= 0;
      end
    end
  end

  // Destination-side logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_reg_valid <= 0;
      dst_reg_valid_sync <= 0;
      dst_reg_data <= 0;
    end else begin
      dst_reg_valid_sync <= dst_reg_valid;
      if (dst_ready_i && dst_valid_o) begin
        dst_reg_valid <= 0;
      end else if (src_reg_valid) begin
        dst_reg_valid <= 1;
        dst_reg_data <= src_reg_data;
      end
    end
  end

  // Output assignments
  assign src_ready_o = !src_reg_valid;
  assign dst_data_o = dst_reg_data;
  assign dst_valid_o = dst_reg_valid;

endmodule
