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
  logic [WIDTH-1:0] sync_data;
  logic sync_valid;
  logic sync_ready;
  logic src_reg_valid;
  logic dst_reg_valid;

  // Source register
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_reg_valid <= 0;
    end else begin
      src_reg_valid <= src_valid_i & src_ready_o;
    end
  end

  // Destination register
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_reg_valid <= 0;
    end else begin
      dst_reg_valid <= dst_valid_o & dst_ready_i;
    end
  end

  // Synchronizer
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      sync_data <= 0;
      sync_valid <= 0;
      sync_ready <= 0;
    end else if (src_valid_i && src_ready_o) begin
      sync_data <= src_data_i;
      sync_valid <= 1;
      sync_ready <= 1;
    end else if (sync_valid && !dst_ready_i) begin
      sync_ready <= 0;
    end else if (sync_valid && dst_ready_i) begin
      sync_valid <= 0;
    end
  end

  // Destination output
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o <= 0;
      dst_valid_o <= 0;
    end else if (sync_valid && dst_ready_i) begin
      dst_data_o <= sync_data;
      dst_valid_o <= 1;
    end else if (dst_valid_o && !dst_ready_i) begin
      dst_valid_o <= 1;
    end else begin
      dst_valid_o <= 0;
    end
  end

  // Source ready
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_o <= 0;
    end else if (src_reg_valid) begin
      src_ready_o <= 0;
    end else begin
      src_ready_o <= 1;
    end
  end

endmodule
