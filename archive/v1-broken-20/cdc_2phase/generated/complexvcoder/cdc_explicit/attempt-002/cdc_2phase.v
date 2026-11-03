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
  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic src_ready_reg;
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic sync_src_valid;
  logic sync_dst_ready;
  logic sync_src_valid_reg;
  logic sync_dst_ready_reg;

  // Sync src_valid to dst_clk domain
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      sync_src_valid_reg <= 0;
    end else begin
      sync_src_valid_reg <= sync_src_valid;
    end
  end

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      sync_src_valid <= 0;
    end else begin
      sync_src_valid <= src_valid_i & src_ready_reg;
    end
  end

  // Sync dst_ready to src_clk domain
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      sync_dst_ready_reg <= 0;
    end else begin
      sync_dst_ready_reg <= sync_dst_ready;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      sync_dst_ready <= 0;
    end else begin
      sync_dst_ready <= dst_ready_i & dst_valid_reg;
    end
  end

  // Register source data and valid signal
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= 0;
      src_valid_reg <= 0;
    end else begin
      if (sync_src_valid_reg) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1;
      end else if (src_valid_reg && src_ready_reg) begin
        src_valid_reg <= 0;
      end
    end
  end

  // Register destination data and valid signal
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= 0;
      dst_valid_reg <= 0;
    end else begin
      if (sync_dst_ready_reg) begin
        dst_data_reg <= src_data_reg;
        dst_valid_reg <= 1;
      end else if (dst_valid_reg && dst_ready_i) begin
        dst_valid_reg <= 0;
      end
    end
  end

  // Drive output signals
  assign src_ready_o = !src_valid_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
