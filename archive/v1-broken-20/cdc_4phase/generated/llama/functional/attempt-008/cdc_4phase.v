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
  logic src_valid_reg;
  logic src_ready_reg;
  logic [1:0] src_handshake_reg;

  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic [1:0] dst_handshake_reg;

  logic src_rst;
  logic dst_rst;

  assign src_rst = ~src_rst_ni;
  assign dst_rst = ~dst_rst_ni;

  always_ff @(posedge src_clk_i or posedge src_rst) begin
    if (src_rst) begin
      src_data_reg <= '0;
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b0;
      src_handshake_reg <= 2'b00;
    end else begin
      if (src_valid_i && src_ready_reg) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1'b1;
        src_handshake_reg <= 2'b01;
      end else if (src_handshake_reg == 2'b01 && src_valid_reg) begin
        src_handshake_reg <= 2'b10;
      end else if (src_handshake_reg == 2'b10 && src_valid_reg) begin
        src_handshake_reg <= 2'b00;
        src_valid_reg <= 1'b0;
      end
      src_ready_reg <= (src_handshake_reg == 2'b00) && (DECOUPLED || src_valid_reg == 1'b0);
    end
  end

  always_ff @(posedge dst_clk_i or posedge dst_rst) begin
    if (dst_rst) begin
      dst_data_reg <= SEND_RESET_MSG? RESET_MSG : '0;
      dst_valid_reg <= SEND_RESET_MSG? 1'b1 : 1'b0;
      dst_ready_reg <= 1'b0;
      dst_handshake_reg <= SEND_RESET_MSG? 2'b01 : 2'b00;
    end else begin
      if (dst_handshake_reg == 2'b01 && dst_valid_reg) begin
        dst_handshake_reg <= 2'b10;
      end else if (dst_handshake_reg == 2'b10 && dst_valid_reg && dst_ready_i) begin
        dst_handshake_reg <= 2'b00;
        dst_valid_reg <= 1'b0;
      end
      dst_ready_reg <= (dst_handshake_reg == 2'b00) && (dst_valid_reg == 1'b0);
      if (dst_ready_reg && src_valid_reg) begin
        dst_data_reg <= src_data_reg;
        dst_valid_reg <= 1'b1;
        dst_handshake_reg <= 2'b01;
      end
    end
  end

  assign src_ready_o = src_ready_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
