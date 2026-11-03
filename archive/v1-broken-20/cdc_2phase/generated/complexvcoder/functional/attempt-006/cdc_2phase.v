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
  logic src_valid_reg;
  logic [WIDTH-1:0] src_data_reg;
  logic dst_valid_reg;
  logic [WIDTH-1:0] dst_data_reg;
  logic src_ready_reg;
  logic dst_ready_reg;
  logic src_valid_sync;
  logic [WIDTH-1:0] src_data_sync;
  logic dst_valid_sync;
  logic dst_ready_sync;

  // Edge detection for source clock
  logic src_clk_edge;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clk_edge <= 0;
    end else begin
      src_clk_edge <= src_clk_i;
    end
  end

  // Edge detection for destination clock
  logic dst_clk_edge;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clk_edge <= 0;
    end else begin
      dst_clk_edge <= dst_clk_i;
    end
  end

  // Register for source data and valid signals
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 0;
      src_data_reg <= 0;
    end else begin
      if (src_valid_i && src_ready_o && src_clk_edge) begin
        src_valid_reg <= 1;
        src_data_reg <= src_data_i;
      end else begin
        src_valid_reg <= 0;
        src_data_reg <= 0;
      end
    end
  end

  // Register for destination data and valid signals
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 0;
      dst_data_reg <= 0;
    end else begin
      if (dst_valid_reg && dst_ready_i && dst_clk_edge) begin
        dst_valid_reg <= 1;
        dst_data_reg <= src_data_reg;
      end else begin
        dst_valid_reg <= 0;
        dst_data_reg <= 0;
      end
    end
  end

  // Handshake logic for source ready
  assign src_ready_o = !(src_valid_reg && src_ready_o);

  // Handshake logic for destination output
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
