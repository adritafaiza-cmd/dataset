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

  // Source domain registers
  reg [WIDTH-1:0] data_reg;
  reg valid_reg;

  // Synchronizers for valid
  reg valid_sync1, valid_sync2;

  // Destination domain signals
  assign dst_valid_o = valid_sync2;
  assign dst_data_o = data_reg;

  // Synchronize valid_reg to destination domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      valid_sync1 <= 1'b0;
      valid_sync2 <= 1'b0;
    end else begin
      valid_sync1 <= valid_reg;
      valid_sync2 <= valid_sync1;
    end
  end

  // Synchronize dst_ready_i to source domain
  reg ready_sync1, ready_sync2;
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      ready_sync1 <= 1'b0;
      ready_sync2 <= 1'b0;
    end else begin
      ready_sync1 <= dst_ready_i;
      ready_sync2 <= ready_sync1;
    end
  end

  // Source logic
  assign src_ready_o = !valid_reg || ready_sync2;

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      valid_reg <= 1'b0;
      data_reg <= {WIDTH{1'b0}};
    end else begin
      if (src_valid_i && src_ready_o) begin
        data_reg <= src_data_i;
        valid_reg <= 1'b1;
      end else if (valid_sync2 && dst_ready_i) begin
        valid_reg <= 1'b0;
      end
    end
  end

endmodule
