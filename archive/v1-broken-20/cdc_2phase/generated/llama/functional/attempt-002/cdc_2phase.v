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

  logic [WIDTH-1:0] fifo_data;
  logic [1:0]       fifo_valid;
  logic             src_ready_int;
  logic             dst_valid_int;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_int <= 1'b1;
      fifo_valid    <= 2'b00;
      fifo_data     <= '0;
    end else if (src_valid_i && src_ready_int) begin
      fifo_valid    <= 2'b01;
      fifo_data     <= src_data_i;
    end else if (fifo_valid == 2'b01 && dst_valid_int) begin
      fifo_valid    <= 2'b10;
    end else if (fifo_valid == 2'b10 &&!dst_valid_int) begin
      fifo_valid    <= 2'b00;
      src_ready_int <= 1'b1;
    end else if (src_valid_i &&!src_ready_int) begin
      src_ready_int <= 1'b0;
    end
  end

  assign src_ready_o = src_ready_int && (fifo_valid == 2'b00);

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_int <= 1'b0;
      dst_valid_o   <= 1'b0;
      dst_data_o     <= '0;
    end else if (fifo_valid == 2'b01) begin
      dst_valid_int <= 1'b1;
      dst_valid_o   <= 1'b1;
      dst_data_o     <= fifo_data;
    end else if (dst_ready_i && dst_valid_int) begin
      dst_valid_int <= 1'b0;
      dst_valid_o   <= 1'b0;
    end
  end

endmodule
