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

  logic [WIDTH-1:0] src_data;
  logic src_valid;
  logic src_ready;
  logic dst_valid;
  logic [WIDTH-1:0] dst_data_int;
  logic [1:0] src_handshake;
  logic [1:0] dst_handshake;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_handshake <= 2'b00;
      src_data <= '0;
      src_valid <= 1'b0;
    end else if (src_valid_i && src_ready) begin
      src_data <= src_data_i;
      src_valid <= 1'b1;
      src_handshake <= 2'b01;
    end else if (src_handshake == 2'b01 && src_valid_i) begin
      src_handshake <= 2'b10;
    end else if (src_handshake == 2'b10 &&!src_valid_i) begin
      src_handshake <= 2'b00;
      src_valid <= 1'b0;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_handshake <= 2'b00;
      dst_data_int <= '0;
      dst_valid <= 1'b0;
    end else if (dst_handshake == 2'b00 && src_valid) begin
      dst_data_int <= src_data;
      dst_valid <= 1'b1;
      dst_handshake <= 2'b01;
    end else if (dst_handshake == 2'b01 && dst_ready_i) begin
      dst_handshake <= 2'b10;
    end else if (dst_handshake == 2'b10 &&!dst_ready_i) begin
      dst_handshake <= 2'b00;
      dst_valid <= 1'b0;
    end
  end

  assign src_ready_o = (DECOUPLED && src_valid_i) || (src_handshake == 2'b00);
  assign dst_data_o = dst_data_int;
  assign dst_valid_o = dst_valid;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready <= 1'b0;
    end else if (src_valid_i && src_ready) begin
      src_ready <= 1'b0;
    end else if (src_handshake == 2'b00) begin
      src_ready <= 1'b1;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      if (SEND_RESET_MSG) begin
        dst_data_int <= RESET_MSG;
        dst_valid <= 1'b1;
      end else begin
        dst_valid <= 1'b0;
      end
    end else if (dst_handshake == 2'b10) begin
      dst_valid <= 1'b0;
    end
  end

endmodule
