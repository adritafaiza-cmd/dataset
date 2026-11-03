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

  logic src_valid_synced;
  logic src_data_synced [WIDTH-1:0];
  logic src_clear_synced;
  logic dst_valid_synced;
  logic dst_data_synced [WIDTH-1:0];
  logic dst_clear_synced;
  logic src_clear_pending_reg;
  logic dst_clear_pending_reg;
  logic src_valid_reg;
  logic src_data_reg [WIDTH-1:0];
  logic dst_valid_reg;
  logic dst_data_reg [WIDTH-1:0];

  // Synchronize src_valid and src_data to dst_clk_i
  sync_flop #(.WIDTH(1), .SYNC_STAGES(SYNC_STAGES)) src_valid_sync_u (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .d_i(src_valid_i),
    .q_o(src_valid_synced)
  );

  sync_flop #(.WIDTH(WIDTH), .SYNC_STAGES(SYNC_STAGES)) src_data_sync_u (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .d_i(src_data_i),
    .q_o(src_data_synced)
  );

  // Synchronize src_clear to dst_clk_i
  sync_flop #(.WIDTH(1), .SYNC_STAGES(SYNC_STAGES)) src_clear_sync_u (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .d_i(src_clear_i),
    .q_o(src_clear_synced)
  );

  // Synchronize dst_valid and dst_data to src_clk_i
  sync_flop #(.WIDTH(1), .SYNC_STAGES(SYNC_STAGES)) dst_valid_sync_u (
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .d_i(dst_valid_o),
    .q_o(dst_valid_synced)
  );

  sync_flop #(.WIDTH(WIDTH), .SYNC_STAGES(SYNC_STAGES)) dst_data_sync_u (
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .d_i(dst_data_o),
    .q_o(dst_data_synced)
  );

  // Synchronize dst_clear to src_clk_i
  sync_flop #(.WIDTH(1), .SYNC_STAGES(SYNC_STAGES)) dst_clear_sync_u (
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .d_i(dst_clear_i),
    .q_o(dst_clear_synced)
  );

  // Clear logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pending_reg <= 1'b0;
    end else if (src_clear_i || (CLEAR_ON_ASYNC_RESET && !src_rst_ni)) begin
      src_clear_pending_reg <= 1'b1;
    end else if (dst_clear_synced) begin
      src_clear_pending_reg <= 1'b0;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pending_reg <= 1'b0;
    end else if (dst_clear_i || (CLEAR_ON_ASYNC_RESET && !dst_rst_ni)) begin
      dst_clear_pending_reg <= 1'b1;
    end else if (src_clear_synced) begin
      dst_clear_pending_reg <= 1'b0;
    end
  end

  assign src_clear_pending_o = src_clear_pending_reg;
  assign dst_clear_pending_o = dst_clear_pending_reg;

  // Valid and ready logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
      src_data_reg <= '0;
    end else if (src_valid_i && src_ready_o) begin
      src_valid_reg <= 1'b1;
      src_data_reg <= src_data_i;
    end else if (dst_valid_synced && dst_ready_i) begin
      src_valid_reg <= 1'b0;
    end else if (src_clear_i || (CLEAR_ON_ASYNC_RESET && !src_rst_ni)) begin
      src_valid_reg <= 1'b0;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
      dst_data_reg <= '0;
    end else if (src_valid_synced && !dst_valid_reg) begin
      dst_valid_reg <= 1'b1;
      dst_data_reg <= src_data_synced;
    end else if (dst_ready_i && dst_valid_reg) begin
      dst_valid_reg <= 1'b0;
    end else if (dst_clear_i || (CLEAR_ON_ASYNC_RESET && !dst_rst_ni)) begin
      dst_valid_reg <= 1'b0;
    end
  end

  assign src_ready_o = !(src_valid_reg && !dst_valid_synced) && !src_clear_pending_reg;
  assign dst_valid_o = dst_valid_reg && !dst_clear_pending_reg;
  assign dst_data_o = dst_data_reg;

endmodule

module sync_flop #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3
)(
  input  clk_i,
  input  rst_ni,
  input  [WIDTH-1:0] d_i,
  output [WIDTH-1:0] q_o
);

  logic [WIDTH-1:0] stage [SYNC_STAGES-1:0];

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (int i = 0; i < SYNC_STAGES; i++) begin
        stage[i] <= '0;
      end
    end else begin
      stage[0] <= d_i;
      for (int i = 1; i < SYNC_STAGES; i++) begin
        stage[i] <= stage[i-1];
      end
    end
  end

  assign q_o = stage[SYNC_STAGES-1];

endmodule
