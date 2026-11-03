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

  logic src_clear_synced;
  logic dst_clear_synced;
  logic src_valid_synced;
  logic src_data_synced [WIDTH-1:0];
  logic src_ready_synced;
  logic dst_valid_synced;
  logic dst_data_synced [WIDTH-1:0];
  logic dst_ready_synced;

  logic src_clear_pending_reg;
  logic dst_clear_pending_reg;

  logic src_valid_reg;
  logic src_data_reg [WIDTH-1:0];
  logic src_ready_reg;

  logic dst_valid_reg;
  logic dst_data_reg [WIDTH-1:0];

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pending_reg <= 1'b0;
      src_valid_reg <= 1'b0;
      src_data_reg <= '0;
      src_ready_reg <= 1'b0;
    end else if (src_clear_i || (CLEAR_ON_ASYNC_RESET && !src_rst_ni)) begin
      src_clear_pending_reg <= 1'b1;
      src_valid_reg <= 1'b0;
      src_data_reg <= '0;
      src_ready_reg <= 1'b0;
    end else if (src_valid_i && src_ready_reg) begin
      src_valid_reg <= 1'b1;
      src_data_reg <= src_data_i;
      src_ready_reg <= 1'b0;
    end else if (src_clear_synced) begin
      src_clear_pending_reg <= 1'b0;
      src_valid_reg <= 1'b0;
      src_data_reg <= '0;
      src_ready_reg <= 1'b1;
    end else if (src_valid_i) begin
      src_ready_reg <= 1'b1;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pending_reg <= 1'b0;
      dst_valid_reg <= 1'b0;
      dst_data_reg <= '0;
    end else if (dst_clear_i || (CLEAR_ON_ASYNC_RESET && !dst_rst_ni)) begin
      dst_clear_pending_reg <= 1'b1;
      dst_valid_reg <= 1'b0;
      dst_data_reg <= '0;
    end else if (dst_valid_synced && dst_ready_i) begin
      dst_valid_reg <= 1'b0;
      dst_data_reg <= '0;
    end else if (src_clear_synced) begin
      dst_clear_pending_reg <= 1'b0;
      dst_valid_reg <= 1'b0;
      dst_data_reg <= '0;
    end else if (src_valid_synced) begin
      dst_valid_reg <= 1'b1;
      dst_data_reg <= src_data_synced;
    end
  end

  always_ff @(posedge src_clk_i) begin
    src_clear_synced <= dst_clear_synced;
    src_valid_synced <= dst_valid_synced;
    src_data_synced <= dst_data_synced;
    src_ready_synced <= dst_ready_synced;
  end

  always_ff @(posedge dst_clk_i) begin
    dst_clear_synced <= src_clear_pending_reg;
    dst_valid_synced <= src_valid_reg;
    dst_data_synced <= src_data_reg;
    dst_ready_synced <= src_ready_reg;
  end

  assign src_clear_pending_o = src_clear_pending_reg;
  assign src_ready_o = src_ready_reg;
  assign dst_clear_pending_o = dst_clear_pending_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

  // Synchronize signals across clock domains
  logic [SYNC_STAGES-1:0] src_clear_sync;
  logic [SYNC_STAGES-1:0] src_valid_sync;
  logic [SYNC_STAGES-1:0] src_data_sync [WIDTH-1:0];
  logic [SYNC_STAGES-1:0] src_ready_sync;
  logic [SYNC_STAGES-1:0] dst_clear_sync;
  logic [SYNC_STAGES-1:0] dst_valid_sync;
  logic [SYNC_STAGES-1:0] dst_data_sync [WIDTH-1:0];
  logic [SYNC_STAGES-1:0] dst_ready_sync;

  always_ff @(posedge src_clk_i) begin
    src_clear_sync[0] <= src_clear_i;
    src_valid_sync[0] <= src_valid_i;
    src_data_sync[0] <= src_data_i;
    src_ready_sync[0] <= src_ready_o;
    for (int i = 1; i < SYNC_STAGES; i++) begin
      src_clear_sync[i] <= src_clear_sync[i-1];
      src_valid_sync[i] <= src_valid_sync[i-1];
      src_data_sync[i] <= src_data_sync[i-1];
      src_ready_sync[i] <= src_ready_sync[i-1];
    end
  end

  always_ff @(posedge dst_clk_i) begin
    dst_clear_sync[0] <= dst_clear_i;
    dst_valid_sync[0] <= dst_valid_o;
    dst_data_sync[0] <= dst_data_o;
    dst_ready_sync[0] <= dst_ready_i;
    for (int i = 1; i < SYNC_STAGES; i++) begin
      dst_clear_sync[i] <= dst_clear_sync[i-1];
      dst_valid_sync[i] <= dst_valid_sync[i-1];
      dst_data_sync[i] <= dst_data_sync[i-1];
      dst_ready_sync[i] <= dst_ready_sync[i-1];
    end
  end

  assign src_clear_synced = src_clear_sync[SYNC_STAGES-1];
  assign src_valid_synced = src_valid_sync[SYNC_STAGES-1];
  assign src_data_synced = src_data_sync[SYNC_STAGES-1];
  assign src_ready_synced = src_ready_sync[SYNC_STAGES-1];
  assign dst_clear_synced = dst_clear_sync[SYNC_STAGES-1];
  assign dst_valid_synced = dst_valid_sync[SYNC_STAGES-1];
  assign dst_data_synced = dst_data_sync[SYNC_STAGES-1];
  assign dst_ready_synced = dst_ready_sync[SYNC_STAGES-1];

endmodule
