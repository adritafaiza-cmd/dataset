module cdc_4phase #(
  parameter WIDTH = 1,
  parameter DECOUPLED = 1,
  parameter SEND_RESET_MSG = 0,
  parameter [WIDTH-1:0] RESET_MSG = {WIDTH{1'b0}}
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
  logic src_ready_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic [WIDTH-1:0] dst_data_reg;
  logic reset_flag;

  // Clock domains crossing logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= 0;
      src_valid_reg <= 0;
      src_ready_reg <= 0;
      reset_flag <= 1;
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1;
      end
      if (DECOUPLED) begin
        src_ready_reg <= dst_ready_i;
      end else begin
        src_ready_reg <= dst_ready_i && !dst_valid_reg;
      end
      reset_flag <= 0;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 0;
      dst_ready_reg <= 0;
      dst_data_reg <= 0;
    end else begin
      if (src_valid_reg && !dst_valid_reg) begin
        dst_valid_reg <= 1;
        dst_data_reg <= src_data_reg;
      end
      if (dst_valid_reg && dst_ready_i) begin
        dst_valid_reg <= 0;
      end
      if (!SEND_RESET_MSG) begin
        dst_ready_reg <= 1;
      end else begin
        dst_ready_reg <= src_ready_o;
      end
    end
  end

  // Output ports
  assign src_ready_o = src_ready_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

  // Send reset message if requested
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= RESET_MSG;
    end else if (SEND_RESET_MSG && reset_flag) begin
      dst_data_reg <= RESET_MSG;
    end
  end

endmodule
