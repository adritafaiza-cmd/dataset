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

logic [WIDTH-1:0] src_data;
logic src_valid;
logic src_ready;

logic [WIDTH-1:0] dst_data;
logic dst_valid;
logic dst_ready;

always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
  if (!src_rst_ni) begin
    src_data <= '0;
    src_valid <= 1'b0;
    src_ready <= 1'b1;
  end else begin
    if (src_valid_i && src_ready) begin
      src_data <= src_data_i;
      src_valid <= 1'b1;
    end else if (src_valid &&!src_ready) begin
      src_data <= src_data;
      src_valid <= 1'b1;
    end else begin
      src_data <= src_data;
      src_valid <= 1'b0;
    end
    src_ready <= src_valid_i? 1'b1 : 1'b0;
  end
end

always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
  if (!dst_rst_ni) begin
    dst_data <= '0;
    dst_valid <= 1'b0;
    dst_ready <= 1'b1;
  end else begin
    if (dst_valid && dst_ready_i) begin
      dst_data <= '0;
      dst_valid <= 1'b0;
    end else if (!dst_valid && dst_ready_i) begin
      dst_data <= '0;
      dst_valid <= 1'b0;
    end else begin
      dst_data <= dst_data;
      dst_valid <= 1'b0;
    end
    dst_ready <= 1'b1;
  end
end

always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
  if (!src_rst_ni) begin
    src_ready_o <= 1'b1;
  end else begin
    src_ready_o <= src_valid? 1'b0 : 1'b1;
  end
end

always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
  if (!dst_rst_ni) begin
    dst_data_o <= '0;
    dst_valid_o <= 1'b0;
  end else begin
    if (dst_valid && dst_ready_i) begin
      dst_data_o <= dst_data;
      dst_valid_o <= 1'b1;
    end else begin
      dst_data_o <= dst_data_o;
      dst_valid_o <= 1'b0;
    end
  end
end

always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
  if (!src_rst_ni) begin
    src_data <= '0;
    src_valid <= 1'b0;
  end else if (src_valid && src_ready) begin
    src_data <= src_data_i;
    src_valid <= 1'b1;
  end else begin
    src_data <= src_data;
    src_valid <= src_valid;
  end
end

always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
  if (!dst_rst_ni) begin
    dst_data <= '0;
    dst_valid <= 1'b0;
  end else if (dst_valid && dst_ready_i) begin
    dst_data <= src_data;
    dst_valid <= 1'b1;
  end else begin
    dst_data <= dst_data;
    dst_valid <= dst_valid;
  end
end

endmodule
