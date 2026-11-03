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

  // Internal registers
  reg [WIDTH-1:0] src_reg;
  reg [WIDTH-1:0] dst_reg;
  reg src_valid_reg;
  reg dst_valid_reg;
  reg src_handshake;
  reg dst_handshake;
  reg send_reset_msg_flag;

  // Source-side logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_reg <= RESET_MSG;
      src_valid_reg <= SEND_RESET_MSG;
      src_handshake <= 0;
      send_reset_msg_flag <= SEND_RESET_MSG;
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_reg <= src_data_i;
        src_valid_reg <= 1;
        src_handshake <= 1;
        send_reset_msg_flag <= 0;
      end else if (src_handshake && dst_handshake) begin
        src_handshake <= 0;
      end
    end
  end

  // Source ready output
  assign src_ready_o = DECOUPLED || !src_valid_reg || (src_handshake && dst_handshake);

  // Destination-side logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_reg <= RESET_MSG;
      dst_valid_reg <= SEND_RESET_MSG;
      dst_handshake <= 0;
    end else begin
      if (src_valid_reg && !dst_valid_reg) begin
        dst_reg <= src_reg;
        dst_valid_reg <= 1;
        dst_handshake <= 0;
      end else if (dst_valid_reg && dst_ready_i) begin
        dst_valid_reg <= 0;
        dst_handshake <= 1;
      end else if (dst_handshake && src_handshake) begin
        dst_handshake <= 0;
      end
    end
  end

  // Destination outputs
  assign dst_data_o = dst_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
