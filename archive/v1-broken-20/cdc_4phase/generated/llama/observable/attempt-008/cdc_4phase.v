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

  logic src_valid_sync, src_ready_sync;
  logic [WIDTH-1:0] src_data_sync;

  logic dst_valid_sync, dst_ready_sync;
  logic [WIDTH-1:0] dst_data_sync;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_q <= 1'b0;
      src_ready_q <= 1'b0;
      src_data_q <= {WIDTH{1'b0}};
    end else begin
      src_valid_q <= src_valid_d;
      src_ready_q <= src_ready_d;
      src_data_q <= src_data_d;
    end
  end

  always_comb begin
    src_valid_d = src_valid_q;
    src_ready_d = src_ready_q;
    src_data_d = src_data_q;

    if (src_valid_i && src_ready_q) begin
      src_valid_d = 1'b1;
      src_data_d = src_data_i;
    end

    if (src_ready_q &&!src_valid_i) begin
      src_ready_d = 1'b0;
    end

    if (src_valid_i &&!src_ready_q) begin
      src_valid_d = 1'b0;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_q <= 1'b0;
      dst_ready_q <= 1'b0;
      dst_data_q <= {WIDTH{1'b0}};
    end else begin
      dst_valid_q <= dst_valid_d;
      dst_ready_q <= dst_ready_d;
      dst_data_q <= dst_data_d;
    end
  end

  always_comb begin
    dst_valid_d = dst_valid_q;
    dst_ready_d = dst_ready_q;
    dst_data_d = dst_data_q;

    if (dst_ready_q && dst_valid_i) begin
      dst_valid_d = 1'b1;
      dst_data_d = dst_data_i;
    end

    if (dst_valid_q &&!dst_ready_i) begin
      dst_valid_d = 1'b0;
    end

    if (dst_ready_q &&!dst_valid_i) begin
      dst_ready_d = 1'b0;
    end
  end

  always_ff @(posedge src_clk_i) begin
    src_valid_sync <= src_valid_q;
  end

  always_ff @(posedge dst_clk_i) begin
    dst_valid_sync <= dst_valid_q;
  end

  always_ff @(posedge src_clk_i) begin
    src_ready_sync <= dst_ready_q;
  end

  always_ff @(posedge dst_clk_i) begin
    dst_ready_sync <= src_ready_q;
  end

  always_ff @(posedge src_clk_i) begin
    src_data_sync <= src_data_q;
  end

  always_ff @(posedge dst_clk_i) begin
    dst_data_sync <= dst_data_q;
  end

  assign src_ready_o = src_ready_sync;
  assign dst_data_o = dst_data_sync;
  assign dst_valid_o = dst_valid_sync;

endmodule
