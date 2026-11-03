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
  logic [WIDTH-1:0] src_data_buffered;
  logic src_valid_buffered;
  logic dst_valid_buffered;
  logic dst_ready_buffered;

  // Source buffer
  logic src_buf_valid_out;
  logic src_buf_ready_in;

  // Destination buffer
  logic dst_buf_valid_out;
  logic dst_buf_ready_in;

  // Handshake logic for source
  logic src_handshake_valid_in;
  logic src_handshake_ready_out;

  // Handshake logic for destination
  logic dst_handshake_valid_in;
  logic dst_handshake_ready_out;

  // Source buffer
  src_buffer #(
    .WIDTH(WIDTH)
  ) src_buf (
    .clk(src_clk_i),
    .rst_n(src_rst_ni),
    .data_in(src_data_i),
    .valid_in(src_valid_i),
    .ready_out(src_ready_o)
  );

  // Destination buffer
  dst_buffer #(
    .WIDTH(WIDTH)
  ) dst_buf (
    .clk(dst_clk_i),
    .rst_n(dst_rst_ni),
    .data_in(dst_data_o),
    .valid_out(dst_valid_o),
    .ready_in(dst_ready_i)
  );

  // Handshake logic for source
  handshake #(
    .WIDTH(1)
  ) src_handshake (
    .clk(src_clk_i),
    .rst_n(src_rst_ni),
    .valid_in(src_valid_i),
    .ready_out(src_ready_o)
  );

  // Handshake logic for destination
  handshake #(
    .WIDTH(1)
  ) dst_handshake (
    .clk(dst_clk_i),
    .rst_n(dst_rst_ni),
    .valid_in(dst_valid_o),
    .ready_out(dst_ready_i)
  );

  // Connections
  assign src_handshake.valid_in = src_buf_valid_out;
  assign src_buf.ready_in = src_handshake.ready_out;
  assign dst_handshake.valid_in = dst_buf_valid_out;
  assign dst_buf.ready_in = dst_handshake.ready_out;

  // Reset behavior
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_buffered <= {WIDTH{1'b0}};
      src_valid_buffered <= 1'b0;
    end else begin
      src_data_buffered <= src_data_i;
      src_valid_buffered <= src_valid_i;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_buffered <= 1'b0;
    end else begin
      dst_valid_buffered <= dst_valid_o;
    end
  end

  // Destination data and valid outputs
  assign dst_data_o = dst_data_buffered;
  assign dst_valid_o = dst_valid_buffered;

endmodule
