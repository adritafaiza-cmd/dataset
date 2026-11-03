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

  logic src_valid_q;
  logic src_valid_d;
  logic [WIDTH-1:0] src_data_q;
  logic [WIDTH-1:0] src_data_d;
  logic dst_valid_q;
  logic dst_valid_d;
  logic [WIDTH-1:0] dst_data_q;
  logic [WIDTH-1:0] dst_data_d;
  logic src_ready_q;
  logic src_ready_d;
  logic dst_ready_q;
  logic dst_ready_d;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
      src_valid_q <= 1'b0;
      src_data_q <= '0;
      src_ready_q <= 1'b1;
    end else begin
      src_valid_q <= src_valid_d;
      src_data_q <= src_data_d;
      src_ready_q <= src_ready_d;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
      dst_valid_q <= 1'b0;
      dst_data_q <= '0;
    end else begin
      dst_valid_q <= dst_valid_d;
      dst_data_q <= dst_data_d;
    end
  end

  always_comb begin
    src_ready_d = ~src_valid_q;
    src_valid_d = src_valid_i & src_ready_q;
    src_data_d = src_data_i;
    dst_valid_d = src_valid_q & ~dst_valid_q;
    dst_data_d = src_data_q;
    dst_valid_o = dst_valid_q;
    dst_data_o = dst_data_q;
    src_ready_o = src_ready_q;
  end

  always_comb begin
    if (dst_valid_q & dst_ready_i) begin
      dst_valid_d = 1'b0;
    end
  end

endmodule
