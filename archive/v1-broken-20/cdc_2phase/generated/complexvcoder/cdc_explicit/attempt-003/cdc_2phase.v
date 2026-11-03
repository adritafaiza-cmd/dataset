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

  // Internal signals for source domain
  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic src_ready_reg;
  logic src_valid_sync;
  logic src_ready_sync;

  // Internal signals for destination domain
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_reg;
  logic dst_ready_sync;

  // Source synchronizer
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_sync <= 1'b0;
      src_ready_sync <= 1'b0;
    end else begin
      src_valid_sync <= src_valid_i;
      src_ready_sync <= src_ready_o;
    end
  end

  // Destination synchronizer
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_sync <= 1'b0;
    end else begin
      dst_ready_sync <= dst_ready_i;
    end
  end

  // Source ready logic
  assign src_ready_o = dst_ready_sync & ~src_valid_sync;

  // Destination data and valid logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= 0;
      dst_valid_reg <= 1'b0;
    end else begin
      if (dst_valid_sync && dst_ready_sync) begin
        dst_data_reg <= src_data_reg;
        dst_valid_reg <= 1'b1;
      end else if (dst_ready_sync) begin
        dst_valid_reg <= 1'b0;
      end
    end
  end

  // Source data and valid logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= 0;
      src_valid_reg <= 1'b0;
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1'b1;
      end else if (src_ready_o) begin
        src_valid_reg <= 1'b0;
      end
    end
  end

  // Destination output
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
