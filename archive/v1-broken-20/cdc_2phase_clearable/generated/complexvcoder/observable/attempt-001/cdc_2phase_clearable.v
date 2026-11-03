module cdc_2phase_clearable #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3,
  parameter CLEAR_ON_ASYNC_RESET = 1
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  src_clear_i,
  output src_clear_pending_o,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,
  input  dst_rst_ni,
  input  dst_clk_i,
  input  dst_clear_i,
  output dst_clear_pending_o,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);

  // Internal signals
  logic [WIDTH-1:0] src_to_dst_sync_data;
  logic src_to_dst_sync_valid;
  logic src_to_dst_sync_ready;
  logic src_to_dst_sync_clear;
  logic src_to_dst_sync_rst;
  logic [WIDTH-1:0] dst_to_src_sync_data;
  logic dst_to_src_sync_valid;
  logic dst_to_src_sync_ready;
  logic dst_to_src_sync_clear;
  logic dst_to_src_sync_rst;

  // Source to Destination synchronization
  src_to_dst_sync #(
    .WIDTH(WIDTH),
    .SYNC_STAGES(SYNC_STAGES)
  ) src_to_dst (
    .data_i(src_data_i),
    .valid_i(src_valid_i),
    .ready_o(src_ready_o),
    .clear_i(src_clear_i),
    .rst_ni(src_rst_ni),
    .data_o(src_to_dst_sync_data),
    .valid_o(src_to_dst_sync_valid),
    .clear_pending_o(src_clear_pending_o)
  );

  // Destination to Source synchronization
  dst_to_src_sync #(
    .WIDTH(WIDTH),
    .SYNC_STAGES(SYNC_STAGES)
  ) dst_to_src (
    .data_i(dst_to_src_sync_data),
    .valid_i(dst_to_src_sync_valid),
    .ready_o(dst_ready_i),
    .clear_i(dst_clear_i),
    .rst_ni(dst_rst_ni),
    .data_o(dst_data_o),
    .valid_o(dst_valid_o),
    .clear_pending_o(dst_clear_pending_o)
  );

endmodule

module src_to_dst_sync #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3
)(
  input  [WIDTH-1:0] data_i,
  input  valid_i,
  output ready_o,
  input  clear_i,
  input  rst_ni,
  output [WIDTH-1:0] data_o,
  output valid_o,
  output clear_pending_o
);

  logic [WIDTH-1:0] data_reg;
  logic valid_reg;
  logic clear_reg;
  logic rst_reg;

  logic [WIDTH-1:0] sync_data;
  logic sync_valid;
  logic sync_ready;
  logic sync_clear;
  logic sync_rst;

  // Registers for synchronization
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      data_reg <= 0;
      valid_reg <= 0;
      clear_reg <= 0;
      rst_reg <= 0;
    end else begin
      data_reg <= data_i;
      valid_reg <= valid_i;
      clear_reg <= clear_i;
      rst_reg <= rst_ni;
    end
  end

  // Clear pending signal
  assign clear_pending_o = clear_reg;

  // Data and valid output
  assign data_o = sync_data;
  assign valid_o = sync_valid;

  // Synchronization logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      sync_data <= 0;
      sync_valid <= 0;
    end else begin
      sync_data <= data_reg;
      sync_valid <= valid_reg;
    end
  end

endmodule

module dst_to_src_sync #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3
)(
  input  [WIDTH-1:0] data_i,
  input  valid_i,
  output ready_o,
  input  clear_i,
  input  rst_ni,
  output [WIDTH-1:0] data_o,
  output valid_o,
  output clear_pending_o
);

  logic [WIDTH-1:0] data_reg;
  logic valid_reg;
  logic clear_reg;
  logic rst_reg;

  logic [WIDTH-1:0] sync_data;
  logic sync_valid;
  logic sync_ready;
  logic sync_clear;
  logic sync_rst;

  // Registers for synchronization
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      data_reg <= 0;
      valid_reg <= 0;
      clear_reg <= 0;
      rst_reg <= 0;
    end else begin
      data_reg <= data_i;
      valid_reg <= valid_i;
      clear_reg <= clear_i;
      rst_reg <= rst_ni;
    end
  end

  // Clear pending signal
  assign clear_pending_o = clear_reg;

  // Data and valid output
  assign data_o = sync_data;
  assign valid_o = sync_valid;

  // Synchronization logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      sync_data <= 0;
      sync_valid <= 0;
    end else begin
      sync_data <= data_reg;
      sync_valid <= valid_reg;
    end
  end

endmodule
