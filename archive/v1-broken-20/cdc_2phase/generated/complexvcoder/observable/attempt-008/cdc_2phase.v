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
  logic [WIDTH-1:0] dst_reg;
  logic dst_valid_reg;

  // Sync to destination module
  sync_to_dst #(.WIDTH(WIDTH)) sync_to_dst_inst (
    .src_rst_ni(src_rst_ni),
    .src_clk_i(src_clk_i),
    .src_data_i(sync_data),
    .src_valid_i(sync_valid),
    .src_ready_o(sync_ready),
    .dst_rst_ni(dst_rst_ni),
    .dst_clk_i(dst_clk_i),
    .dst_data_o(dst_data_o),
    .dst_valid_o(dst_valid_o),
    .dst_ready_i(dst_ready_i)
  );

  // Synchronizer for source data
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      sync_data <= 0;
      sync_valid <= 0;
    end else if (src_valid_i && src_ready_o) begin
      sync_data <= src_data_i;
      sync_valid <= 1;
    end else if (sync_valid && sync_ready) begin
      sync_valid <= 0;
    end
  end

  // Destination register
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_reg <= 0;
      dst_valid_reg <= 0;
    end else if (dst_ready_i && dst_valid_o) begin
      dst_reg <= dst_data_o;
      dst_valid_reg <= 1;
    end else if (dst_valid_reg && dst_ready_i) begin
      dst_valid_reg <= 0;
    end
  end

  // Ready signal for source
  assign src_ready_o = !sync_valid;

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

  // Internal signals
  logic [WIDTH-1:0] dst_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;

  // Synchronizer for destination data
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_reg <= 0;
      dst_valid_reg <= 0;
    end else if (src_valid_i && src_ready_o) begin
      dst_reg <= src_data_i;
      dst_valid_reg <= 1;
    end else if (dst_valid_reg && dst_ready_i) begin
      dst_valid_reg <= 0;
    end
  end

  // Destination ready signal
  assign dst_ready_o = !dst_valid_reg;

  // Register for output data
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o <= 0;
      dst_valid_o <= 0;
    end else if (dst_ready_i && dst_valid_reg) begin
      dst_data_o <= dst_reg;
      dst_valid_o <= 1;
    end else if (dst_valid_o && dst_ready_i) begin
      dst_valid_o <= 0;
    end
  end

endmodule
