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

  // Internal signals for synchronization
  logic [WIDTH-1:0] sync_data_o;
  logic sync_valid_o;
  logic sync_ready_i;
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;

  // Sync to destination module
  sync_to_dst #(
    .WIDTH(WIDTH)
  ) sync_to_dst_inst (
    .src_rst_ni(src_rst_ni),
    .src_clk_i(src_clk_i),
    .src_data_i(sync_data_o),
    .src_valid_i(sync_valid_o),
    .src_ready_o(sync_ready_i),
    .dst_rst_ni(dst_rst_ni),
    .dst_clk_i(dst_clk_i),
    .dst_data_o(dst_data_o),
    .dst_valid_o(dst_valid_o),
    .dst_ready_i(dst_ready_i)
  );

  // Synchronize source signals to destination clock domain
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_o <= 1'b0;
      sync_data_o <= {WIDTH{1'b0}};
      sync_valid_o <= 1'b0;
      sync_ready_i <= 1'b0;
    end else begin
      if (src_valid_i && dst_ready_i) begin
        sync_data_o <= src_data_i;
        sync_valid_o <= 1'b1;
        src_ready_o <= 1'b1;
      end else begin
        sync_valid_o <= 1'b0;
        src_ready_o <= 1'b0;
      end
    end
  end

endmodule

module sync_to_dst #(
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

  // Internal signals for synchronization
  logic [WIDTH-1:0] data_reg;
  logic valid_reg;
  logic ready_reg;

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o <= {WIDTH{1'b0}};
      dst_valid_o <= 1'b0;
      dst_ready_o <= 1'b1;
    end else begin
      if (src_valid_i && dst_ready_i) begin
        data_reg <= src_data_i;
        valid_reg <= 1'b1;
        dst_data_o <= data_reg;
        dst_valid_o <= 1'b1;
      end else begin
        valid_reg <= 1'b0;
        dst_valid_o <= 1'b0;
      end
      dst_ready_o <= src_ready_o;
    end
  end

endmodule
