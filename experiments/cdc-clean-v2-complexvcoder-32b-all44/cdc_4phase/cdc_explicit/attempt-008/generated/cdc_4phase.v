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

  reg [WIDTH-1:0] src_reg;
  reg src_valid_reg;
  reg src_ready_reg;
  reg [WIDTH-1:0] dst_reg;
  reg dst_valid_reg;
  reg dst_valid_reg_1;
  reg dst_valid_reg_2;
  reg reset_msg_flag;

  // Source-clock domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_reg <= RESET_MSG;
      src_valid_reg <= 0;
      src_ready_reg <= 0;
      reset_msg_flag <= SEND_RESET_MSG;
    end else begin
      if (reset_msg_flag) begin
        src_reg <= RESET_MSG;
        src_valid_reg <= 1;
        reset_msg_flag <= 0;
      end else if (src_valid_i && src_ready_reg) begin
        src_reg <= src_data_i;
        src_valid_reg <= src_valid_i;
      end
      src_ready_reg <= DECOUPLED || !src_valid_reg;
    end
  end

  assign src_ready_o = src_ready_reg;

  // Destination-clock domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_reg <= RESET_MSG;
      dst_valid_reg <= 0;
      dst_valid_reg_1 <= 0;
      dst_valid_reg_2 <= 0;
    end else begin
      dst_valid_reg_1 <= src_valid_reg;
      dst_valid_reg_2 <= dst_valid_reg_1;
      if (dst_valid_reg_2 && !dst_ready_i) begin
        dst_reg <= src_reg;
      end
      dst_valid_reg <= dst_valid_reg_2;
    end
  end

  assign dst_data_o = dst_reg;
  assign dst_valid_o = dst_valid_reg_2 && !dst_ready_i;

endmodule
