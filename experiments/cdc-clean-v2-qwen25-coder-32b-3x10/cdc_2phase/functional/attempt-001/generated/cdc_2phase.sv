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

  // Source domain signals
  logic src_valid_sync;
  logic [WIDTH-1:0] src_data_sync;

  // Destination domain signals
  logic dst_valid_reg;
  logic [WIDTH-1:0] dst_data_reg;

  // Synchronizer for src_valid_i to destination domain
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync <= 1'b0;
    end else begin
      src_valid_sync <= src_valid_i;
    end
  end

  // Synchronizer for src_data_i to destination domain
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_data_sync <= '0;
    end else if (src_valid_sync) begin
      src_data_sync <= src_data_i;
    end
  end

  // Source ready signal
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_o <= 1'b0;
    end else begin
      src_ready_o <= !dst_valid_reg;
    end
  end

  // Destination valid and data register
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
      dst_data_reg <= '0;
    end else if (src_valid_sync && !dst_valid_reg) begin
      dst_valid_reg <= 1'b1;
      dst_data_reg <= src_data_sync;
    end else if (dst_valid_reg && dst_ready_i) begin
      dst_valid_reg <= 1'b0;
    end
  end

  // Destination outputs
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
