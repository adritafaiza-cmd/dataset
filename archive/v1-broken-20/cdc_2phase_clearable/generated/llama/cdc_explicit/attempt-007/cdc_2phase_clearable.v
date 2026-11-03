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

  logic src_valid_sync;
  logic [WIDTH-1:0] src_data_sync;
  logic src_clear_sync;
  logic dst_valid_sync;
  logic [WIDTH-1:0] dst_data_sync;
  logic dst_clear_sync;
  logic src_clear_pending;
  logic dst_clear_pending;
  logic src_valid_reg;
  logic [WIDTH-1:0] src_data_reg;
  logic dst_valid_reg;
  logic [WIDTH-1:0] dst_data_reg;

  // Synchronize signals from source clock domain to destination clock domain
  sync #(.WIDTH(1), .SYNC_STAGES(SYNC_STAGES)) src_valid_sync_u (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .data_i(src_valid_sync),
    .data_o(dst_valid_sync)
  );

  sync #(.WIDTH(WIDTH), .SYNC_STAGES(SYNC_STAGES)) src_data_sync_u (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .data_i(src_data_sync),
    .data_o(dst_data_sync)
  );

  sync #(.WIDTH(1), .SYNC_STAGES(SYNC_STAGES)) src_clear_sync_u (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .data_i(src_clear_sync),
    .data_o(dst_clear_sync)
  );

  // Synchronize signals from destination clock domain to source clock domain
  sync #(.WIDTH(1), .SYNC_STAGES(SYNC_STAGES)) dst_valid_sync_u (
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .data_i(dst_valid_sync),
    .data_o(src_valid_sync)
  );

  sync #(.WIDTH(1), .SYNC_STAGES(SYNC_STAGES)) dst_clear_sync_u (
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .data_i(dst_clear_sync),
    .data_o(src_clear_sync)
  );

  // Source clock domain logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
      src_data_reg <= '0;
      src_clear_pending <= 1'b0;
    end else if (src_clear_i || (CLEAR_ON_ASYNC_RESET && !src_rst_ni)) begin
      src_valid_reg <= 1'b0;
      src_data_reg <= '0;
      src_clear_pending <= 1'b1;
    end else if (src_valid_i && src_ready_o) begin
      src_valid_reg <= 1'b1;
      src_data_reg <= src_data_i;
      src_clear_pending <= 1'b0;
    end
  end

  assign src_ready_o = !src_valid_reg || src_valid_sync;
  assign src_clear_pending_o = src_clear_pending;

  // Destination clock domain logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
      dst_data_reg <= '0;
      dst_clear_pending <= 1'b0;
    end else if (dst_clear_i || (CLEAR_ON_ASYNC_RESET && !dst_rst_ni)) begin
      dst_valid_reg <= 1'b0;
      dst_data_reg <= '0;
      dst_clear_pending <= 1'b1;
    end else if (dst_valid_sync && dst_ready_i) begin
      dst_valid_reg <= 1'b1;
      dst_data_reg <= dst_data_sync;
      dst_clear_pending <= 1'b0;
    end
  end

  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_clear_pending_o = dst_clear_pending;

  // Update synchronized signals
  always_ff @(posedge src_clk_i) begin
    src_valid_sync <= src_valid_reg;
    src_data_sync <= src_data_reg;
    src_clear_sync <= src_clear_pending;
  end

  always_ff @(posedge dst_clk_i) begin
    dst_valid_sync <= dst_valid_reg;
    dst_data_sync <= dst_data_reg;
    dst_clear_sync <= dst_clear_pending;
  end

endmodule

module sync #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3
)(
  input  clk_i,
  input  rst_ni,
  input  [WIDTH-1:0] data_i,
  output [WIDTH-1:0] data_o
);

  logic [WIDTH-1:0] data_sync [SYNC_STAGES-1:0];

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (int i = 0; i < SYNC_STAGES; i++) begin
        data_sync[i] <= '0;
      end
    end else begin
      data_sync[0] <= data_i;
      for (int i = 1; i < SYNC_STAGES; i++) begin
        data_sync[i] <= data_sync[i-1];
      end
    end
  end

  assign data_o = data_sync[SYNC_STAGES-1];

endmodule
