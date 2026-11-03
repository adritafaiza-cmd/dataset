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
  logic [WIDTH-1:0] src_reg_out;
  logic src_valid_reg_out;
  logic dst_reg_out;
  logic dst_valid_reg_out;

  // Source register
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_reg_out <= {WIDTH{1'b0}};
      src_valid_reg_out <= 1'b0;
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_reg_out <= src_data_i;
        src_valid_reg_out <= 1'b1;
      end else if (dst_valid_reg_out) begin
        src_valid_reg_out <= 1'b0;
      end
    end
  end

  // Destination register
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_reg_out <= {WIDTH{1'b0}};
      dst_valid_reg_out <= 1'b0;
    end else begin
      if (dst_valid_reg_out && dst_ready_i) begin
        dst_valid_reg_out <= 1'b0;
      end else if (src_valid_reg_out) begin
        dst_reg_out <= src_reg_out;
        dst_valid_reg_out <= 1'b1;
      end
    end
  end

  // Handshake logic
  assign src_ready_o = !src_valid_reg_out;

endmodule
