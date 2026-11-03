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

  // Intermediate signals for clock-domain crossing
  logic [WIDTH-1:0] src_data_sync;
  logic src_valid_sync;
  logic dst_valid_sync;

  // Synchronizers for src_valid and src_data
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_sync <= '0;
      src_valid_sync <= 1'b0;
    end else begin
      if (src_valid_i) begin
        src_data_sync <= src_data_i;
        src_valid_sync <= 1'b1;
      end else if (dst_valid_sync) begin
        src_valid_sync <= 1'b0;
      end
    end
  end

  // Synchronizer for dst_valid
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_sync <= 1'b0;
    end else begin
      dst_valid_sync <= src_valid_sync;
    end
  end

  // Output assignments
  assign src_ready_o = !src_valid_sync;
  assign dst_data_o = src_data_sync;
  assign dst_valid_o = dst_valid_sync & !dst_ready_i;

endmodule
