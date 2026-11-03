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

  // Internal signals
  reg [WIDTH-1:0] src_ff_data;
  reg             src_ff_valid;
  reg [WIDTH-1:0] dst_ff_data;
  reg             dst_ff_valid;
  reg             src_ready;
  reg             dst_valid;

  // Source clock domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ff_data  <= '0;
      src_ff_valid <= 0;
      src_ready    <= 1;
    end else begin
      if (src_ready && src_valid_i) begin
        src_ff_data  <= src_data_i;
        src_ff_valid <= 1;
        src_ready    <= 0;
      end else if (dst_valid) begin
        src_ready    <= 1;
      end
    end
  end

  // Destination clock domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ff_data  <= '0;
      dst_ff_valid <= 0;
      dst_valid    <= 0;
    end else begin
      if (!dst_valid && src_ff_valid) begin
        dst_ff_data  <= src_ff_data;
        dst_ff_valid <= 1;
        dst_valid    <= 1;
      end else if (dst_valid && dst_ready_i) begin
        dst_ff_valid <= 0;
        dst_valid    <= 0;
      end
    end
  end

  // Output assignments
  assign src_ready_o = src_ready;
  assign dst_data_o  = dst_ff_data;
  assign dst_valid_o = dst_valid;

endmodule
