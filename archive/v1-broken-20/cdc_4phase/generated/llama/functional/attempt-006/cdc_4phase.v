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

  logic [WIDTH-1:0] src_data_reg;
  logic [WIDTH-1:0] dst_data_reg;
  logic src_valid_reg;
  logic dst_valid_reg;
  logic src_ready_reg;
  logic dst_ready_reg;
  logic src_handshake;
  logic dst_handshake;
  logic src_handshake_reg;
  logic dst_handshake_reg;
  logic src_rst;
  logic dst_rst;

  assign src_rst = ~src_rst_ni;
  assign dst_rst = ~dst_rst_ni;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
      src_data_reg <= '0;
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b0;
      src_handshake_reg <= 1'b0;
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1'b1;
      end
      if (src_handshake) begin
        src_valid_reg <= 1'b0;
      end
      src_ready_reg <= (src_valid_i && src_ready_o) || (src_valid_reg && ~src_handshake_reg);
      src_handshake_reg <= src_valid_reg && src_ready_o;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
      dst_data_reg <= SEND_RESET_MSG? RESET_MSG : '0;
      dst_valid_reg <= SEND_RESET_MSG? 1'b1 : 1'b0;
      dst_ready_reg <= 1'b0;
      dst_handshake_reg <= 1'b0;
    end else begin
      if (dst_handshake) begin
        dst_valid_reg <= 1'b0;
      end
      if (src_handshake_reg) begin
        dst_data_reg <= src_data_reg;
        dst_valid_reg <= 1'b1;
      end
      dst_ready_reg <= dst_valid_o && dst_ready_i;
      dst_handshake_reg <= dst_valid_o && dst_ready_i;
    end
  end

  assign src_handshake = dst_handshake_reg;
  assign dst_handshake = src_handshake_reg;

  assign src_ready_o = src_ready_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
