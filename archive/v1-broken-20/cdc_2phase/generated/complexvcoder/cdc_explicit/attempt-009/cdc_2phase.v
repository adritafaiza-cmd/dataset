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
  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic dst_data_reg;
  logic dst_valid_reg;
  logic src_ready;
  logic dst_ready;

  // Source register
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= 0;
      src_valid_reg <= 0;
    end else begin
      src_data_reg <= src_data_i;
      src_valid_reg <= src_valid_i;
    end
  end

  // Destination register
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= 0;
      dst_valid_reg <= 0;
    end else begin
      dst_data_reg <= src_data_reg;
      dst_valid_reg <= src_valid_reg;
    end
  end

  // Handshake logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready <= 0;
    end else begin
      src_ready <= dst_ready_i;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready <= 0;
    end else begin
      dst_ready <= dst_ready_i && dst_valid_reg;
    end
  end

  // Output assignments
  assign src_ready_o = src_ready;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
