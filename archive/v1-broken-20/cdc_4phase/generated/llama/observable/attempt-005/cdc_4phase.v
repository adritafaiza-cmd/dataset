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

  logic src_valid_q, src_valid_d;
  logic src_ready_q, src_ready_d;
  logic [WIDTH-1:0] src_data_q, src_data_d;

  logic dst_valid_q, dst_valid_d;
  logic dst_ready_q, dst_ready_d;
  logic [WIDTH-1:0] dst_data_q, dst_data_d;

  logic src_handshake_q, src_handshake_d;
  logic dst_handshake_q, dst_handshake_d;

  logic src_rst, dst_rst;

  assign src_rst = ~src_rst_ni;
  assign dst_rst = ~dst_rst_ni;

  always_ff @(posedge src_clk_i or posedge src_rst) begin
    if (src_rst) begin
      src_valid_q <= 1'b0;
      src_ready_q <= 1'b1;
      src_handshake_q <= 1'b0;
      src_data_q <= RESET_MSG;
    end else begin
      src_valid_q <= src_valid_d;
      src_ready_q <= src_ready_d;
      src_handshake_q <= src_handshake_d;
      src_data_q <= src_data_d;
    end
  end

  always_comb begin
    src_valid_d = src_valid_q;
    src_ready_d = src_ready_q;
    src_handshake_d = src_handshake_q;
    src_data_d = src_data_q;

    if (src_valid_i && src_ready_q) begin
      src_valid_d = 1'b1;
      src_data_d = src_data_i;
      src_handshake_d = 1'b1;
    end

    if (src_handshake_q && ~src_valid_i) begin
      src_handshake_d = 1'b0;
    end

    if (src_valid_q && ~src_valid_i) begin
      src_valid_d = 1'b0;
    end

    if (src_ready_q && src_valid_i) begin
      src_ready_d = 1'b0;
    end

    if (~src_valid_i && ~src_handshake_q) begin
      src_ready_d = 1'b1;
    end
  end

  always_ff @(posedge dst_clk_i or posedge dst_rst) begin
    if (dst_rst) begin
      dst_valid_q <= 1'b0;
      dst_ready_q <= 1'b1;
      dst_handshake_q <= 1'b0;
      dst_data_q <= RESET_MSG;
    end else begin
      dst_valid_q <= dst_valid_d;
      dst_ready_q <= dst_ready_d;
      dst_handshake_q <= dst_handshake_d;
      dst_data_q <= dst_data_d;
    end
  end

  always_comb begin
    dst_valid_d = dst_valid_q;
    dst_ready_d = dst_ready_q;
    dst_handshake_d = dst_handshake_q;
    dst_data_d = dst_data_q;

    if (dst_ready_i && dst_valid_q) begin
      dst_valid_d = 1'b0;
      dst_handshake_d = 1'b1;
    end

    if (dst_handshake_q && ~dst_ready_i) begin
      dst_handshake_d = 1'b0;
    end

    if (dst_valid_q && ~dst_ready_i) begin
      dst_valid_d = 1'b0;
    end

    if (dst_ready_q && dst_valid_q) begin
      dst_ready_d = 1'b0;
    end

    if (~dst_valid_q && ~dst_handshake_q) begin
      dst_ready_d = 1'b1;
    end
  end

  logic [1:0] src_cnt_q, src_cnt_d;
  logic [1:0] dst_cnt_q, dst_cnt_d;

  always_ff @(posedge src_clk_i or posedge src_rst) begin
    if (src_rst) begin
      src_cnt_q <= 2'b00;
    end else begin
      src_cnt_q <= src_cnt_d;
    end
  end

  always_comb begin
    src_cnt_d = src_cnt_q;

    if (src_valid_i && src_ready_q) begin
      src_cnt_d = src_cnt_q + 1'b1;
    end

    if (src_handshake_q && ~src_valid_i) begin
      src_cnt_d = src_cnt_q - 1'b1;
    end
  end

  always_ff @(posedge dst_clk_i or posedge dst_rst) begin
    if (dst_rst) begin
      dst_cnt_q <= 2'b00;
    end else begin
      dst_cnt_q <= dst_cnt_d;
    end
  end

  always_comb begin
    dst_cnt_d = dst_cnt_q;

    if (dst_ready_i && dst_valid_q) begin
      dst_cnt_d = dst_cnt_q + 1'b1;
    end

    if (dst_handshake_q && ~dst_ready_i) begin
      dst_cnt_d = dst_cnt_q - 1'b1;
    end
  end

  assign src_ready_o = src_ready_q;
  assign dst_data_o = dst_data_q;
  assign dst_valid_o = dst_valid_q;

  always_ff @(posedge src_clk_i or posedge src_rst) begin
    if (src_rst) begin
      src_data_q <= RESET_MSG;
    end else if (src_valid_i && src_ready_q) begin
      src_data_q <= src_data_i;
    end
  end

  always_ff @(posedge dst_clk_i or posedge dst_rst) begin
    if (dst_rst) begin
      dst_data_q <= RESET_MSG;
    end else if (dst_ready_i && dst_valid_q) begin
      dst_data_q <= src_data_q;
    end
  end

endmodule
