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

  // FIFO control signals
  logic [WIDTH-1:0] fifo_data;
  logic fifo_valid, fifo_ready;

  // Cross-domain FIFO
  cdc_fifo #(
    .WIDTH(WIDTH)
  ) cdc_fifo_inst (
    .src_rst_ni(src_rst_ni),
    .src_clk_i(src_clk_i),
    .src_data_i(src_data_i),
    .src_valid_i(src_valid_i),
    .src_ready_o(src_ready_o),
    .dst_rst_ni(dst_rst_ni),
    .dst_clk_i(dst_clk_i),
    .dst_data_o(fifo_data),
    .dst_valid_o(fifo_valid),
    .dst_ready_i(fifo_ready)
  );

  // Destination side logic
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_reg;

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= '0;
      dst_valid_reg <= 1'b0;
    end else begin
      if (fifo_valid && fifo_ready) begin
        dst_data_reg <= fifo_data;
        dst_valid_reg <= 1'b1;
      end else if (dst_ready_i) begin
        dst_valid_reg <= 1'b0;
      end
    end
  end

  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;
  assign fifo_ready = dst_ready_i || !dst_valid_reg;

endmodule

module cdc_fifo #(
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

  // FIFO storage
  logic [WIDTH-1:0] fifo_data;
  logic fifo_valid;

  // Source side write logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      fifo_data <= '0;
      fifo_valid <= 1'b0;
    end else if (src_valid_i && !fifo_valid) begin
      fifo_data <= src_data_i;
      fifo_valid <= 1'b1;
    end else if (fifo_valid && dst_ready_i) begin
      fifo_valid <= 1'b0;
    end
  end

  // Destination side read logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o <= '0;
      dst_valid_o <= 1'b0;
    end else begin
      if (fifo_valid && !dst_valid_o) begin
        dst_data_o <= fifo_data;
        dst_valid_o <= 1'b1;
      end else if (dst_ready_i) begin
        dst_valid_o <= 1'b0;
      end
    end
  end

  assign src_ready_o = !fifo_valid;

endmodule
