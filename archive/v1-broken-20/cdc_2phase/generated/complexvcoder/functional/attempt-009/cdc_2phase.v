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
  logic [WIDTH-1:0] dst_data_sync;

  // Register the source valid and data signals to synchronize with the destination clock domain
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync <= 1'b0;
      src_data_sync <= {WIDTH{1'b0}};
    end else begin
      src_valid_sync <= src_valid_reg;
      src_data_sync <= src_data_reg;
    end
  end

  // Register the destination valid and data signals to synchronize with the source clock domain
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_valid_sync <= 1'b0;
      dst_data_sync <= {WIDTH{1'b0}};
    end else begin
      dst_valid_sync <= dst_valid_reg;
      dst_data_sync <= dst_data_reg;
    end
  end

  // Logic to handle source interface
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
      src_data_reg <= {WIDTH{1'b0}};
      src_ready_reg <= 1'b0;
    end else begin
      if (src_ready_reg && src_valid_sync) begin
        src_valid_reg <= 1'b0;
        src_data_reg <= {WIDTH{1'b0}};
        src_ready_reg <= 1'b0;
      end else if (src_valid_i && src_ready_o) begin
        src_valid_reg <= src_valid_i;
        src_data_reg <= src_data_i;
        src_ready_reg <= src_ready_o;
      end
    end
  end

  // Logic to handle destination interface
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
      dst_data_reg <= {WIDTH{1'b0}};
      dst_ready_reg <= 1'b0;
    end else begin
      if (dst_ready_reg && dst_valid_sync) begin
        dst_valid_reg <= 1'b0;
        dst_data_reg <= {WIDTH{1'b0}};
        dst_ready_reg <= 1'b0;
      end else if (dst_ready_i && dst_valid_sync) begin
        dst_valid_reg <= dst_valid_sync;
        dst_data_reg <= dst_data_sync;
        dst_ready_reg <= dst_ready_i;
      end
    end
  end

  // Assign outputs
  assign src_ready_o = src_ready_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
