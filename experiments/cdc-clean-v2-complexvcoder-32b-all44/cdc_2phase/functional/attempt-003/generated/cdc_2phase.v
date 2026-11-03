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

  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  reg src_ready;
  reg dst_valid_sync0;
  reg dst_valid_sync1;

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg  <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_ready     <= 1'b1;
    end else begin
      if (src_valid_i && src_ready) begin
        src_data_reg  <= src_data_i;
        src_valid_reg <= src_valid_i;
        src_ready     <= 1'b0;
      end else begin
        src_ready     <= 1'b1;
      end
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg    <= {WIDTH{1'b0}};
      dst_valid_reg   <= 1'b0;
      dst_valid_sync0 <= 1'b0;
      dst_valid_sync1 <= 1'b0;
    end else begin
      dst_valid_sync0 <= src_valid_reg;
      dst_valid_sync1 <= dst_valid_sync0;

      if (dst_valid_sync1) begin
        dst_data_reg  <= src_data_reg;
        dst_valid_reg <= dst_valid_sync1;
      end

      if (dst_valid_reg && dst_ready_i) begin
        dst_valid_reg <= 1'b0;
      end
    end
  end

  assign src_ready_o = src_ready;
  assign dst_data_o  = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
