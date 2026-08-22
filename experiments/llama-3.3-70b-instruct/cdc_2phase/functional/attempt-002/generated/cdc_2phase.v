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

  logic [WIDTH-1:0] data;
  logic             valid;
  logic             ready;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_o <= 1'b0;
      data        <= '0;
      valid       <= 1'b0;
      ready       <= 1'b1;
    end else if (src_valid_i && ready) begin
      src_ready_o <= 1'b0;
      data        <= src_data_i;
      valid       <= 1'b1;
      ready       <= 1'b0;
    end else if (!src_valid_i && !valid) begin
      src_ready_o <= 1'b1;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_o <= 1'b0;
      dst_data_o  <= '0;
    end else if (valid && dst_ready_i) begin
      dst_valid_o <= 1'b0;
      dst_data_o  <= '0;
      ready       <= 1'b1;
      valid       <= 1'b0;
    end else if (valid && !dst_ready_i) begin
      dst_valid_o <= 1'b1;
      dst_data_o  <= data;
    end else if (!valid && !dst_valid_o) begin
      dst_valid_o <= 1'b0;
      dst_data_o  <= '0;
    end
  end

  assign src_ready_o = ready && !valid;

endmodule
