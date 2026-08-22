module cdc_2phase #(
  parameter WIDTH = 1
)(
  input                  src_rst_ni,
  input                  src_clk_i,
  input      [WIDTH-1:0] src_data_i,
  input                  src_valid_i,
  output                 src_ready_o,

  input                  dst_rst_ni,
  input                  dst_clk_i,
  output     [WIDTH-1:0] dst_data_o,
  output                 dst_valid_o,
  input                  dst_ready_i
);

  logic [WIDTH-1:0] fifo_data;
  logic             fifo_valid;
  logic             fifo_ready;

  assign src_ready_o = ~fifo_valid;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
      fifo_valid <= 1'b0;
      fifo_data  <= '0;
    end else if (src_valid_i && ~fifo_valid) begin
      fifo_valid <= 1'b1;
      fifo_data  <= src_data_i;
    end
  end

  assign dst_data_o = fifo_data;
  assign dst_valid_o = fifo_valid;

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
      fifo_valid <= 1'b0;
    end else if (fifo_valid && dst_ready_i) begin
      fifo_valid <= 1'b0;
    end
  end

endmodule
