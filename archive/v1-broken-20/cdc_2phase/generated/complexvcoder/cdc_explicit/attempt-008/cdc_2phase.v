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
  logic dst_valid_reg;
  logic [WIDTH-1:0] dst_data_reg;
  logic src_ready_reg;
  logic dst_ready_reg;
  logic transfer_flag;

  // Synchronizers for source domain
  logic [1:0] src_valid_sync;
  logic [1:0] src_data_sync;
  logic [1:0] src_ready_sync;

  // Synchronizers for destination domain
  logic [1:0] dst_valid_sync;
  logic [1:0] dst_data_sync;
  logic [1:0] dst_ready_sync;

  // Register source valid and data on src_clk_i edge
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
      src_data_reg <= {WIDTH{1'b0}};
    end else begin
      src_valid_reg <= src_valid_i;
      src_data_reg <= src_data_i;
    end
  end

  // Register destination valid and data on dst_clk_i edge
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
      dst_data_reg <= {WIDTH{1'b0}};
    end else begin
      dst_valid_reg <= dst_valid_i;
      dst_data_reg <= dst_data_i;
    end
  end

  // Synchronize src_valid and src_data to dst_clk_i domain
  assign src_valid_sync[0] = src_valid_reg;
  assign src_data_sync[0] = src_data_reg;
  assign src_ready_sync[0] = src_ready_reg;

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync[1] <= 1'b0;
      src_data_sync[1] <= {WIDTH{1'b0}};
      src_ready_sync[1] <= 1'b0;
    end else begin
      src_valid_sync[1] <= src_valid_sync[0];
      src_data_sync[1] <= src_data_sync[0];
      src_ready_sync[1] <= src_ready_sync[0];
    end
  end

  // Synchronize dst_valid and dst_data to src_clk_i domain
  assign dst_valid_sync[0] = dst_valid_reg;
  assign dst_data_sync[0] = dst_data_reg;
  assign dst_ready_sync[0] = dst_ready_reg;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_valid_sync[1] <= 1'b0;
      dst_data_sync[1] <= {WIDTH{1'b0}};
      dst_ready_sync[1] <= 1'b0;
    end else begin
      dst_valid_sync[1] <= dst_valid_sync[0];
      dst_data_sync[1] <= dst_data_sync[0];
      dst_ready_sync[1] <= dst_ready_sync[0];
    end
  end

  // Register destination ready on dst_clk_i edge
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_reg <= 1'b0;
    end else begin
      dst_ready_reg <= dst_ready_i;
    end
  end

  // Register source ready on src_clk_i edge
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_reg <= 1'b0;
    end else begin
      src_ready_reg <= src_ready_i;
    end
  end

  // Set src_ready_o low when a new source item cannot safely be accepted
  assign src_ready_o = !src_valid_reg || dst_ready_reg;

  // Set dst_valid_o and dst_data_o based on synchronization
  assign dst_valid_o = dst_valid_sync[1];
  assign dst_data_o = dst_data_sync[1];

endmodule
