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
  logic src_valid_sync_ff;
  logic [WIDTH-1:0] src_data_sync;
  logic src_clear_sync;
  logic src_clear_ff;
  logic src_clear_pending_ff;
  logic src_isolate;
  logic src_isolate_ff;

  logic dst_valid_sync;
  logic dst_valid_sync_ff;
  logic [WIDTH-1:0] dst_data_sync;
  logic dst_clear_sync;
  logic dst_clear_ff;
  logic dst_clear_pending_ff;
  logic dst_isolate;
  logic dst_isolate_ff;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_sync <= 1'b0;
      src_data_sync <= '0;
      src_clear_sync <= 1'b0;
      src_clear_ff <= 1'b0;
      src_clear_pending_ff <= 1'b0;
      src_isolate <= 1'b0;
      src_isolate_ff <= 1'b0;
    end else begin
      src_valid_sync <= src_valid_i;
      src_data_sync <= src_data_i;
      src_clear_sync <= src_clear_i;
      src_clear_ff <= src_clear_i || (CLEAR_ON_ASYNC_RESET &&!src_rst_ni);
      src_clear_pending_ff <= src_clear_i || src_clear_pending_ff;
      src_isolate <= src_clear_i || src_isolate_ff;
      src_isolate_ff <= src_clear_i || src_isolate_ff;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_sync <= 1'b0;
      dst_data_sync <= '0;
      dst_clear_sync <= 1'b0;
      dst_clear_ff <= 1'b0;
      dst_clear_pending_ff <= 1'b0;
      dst_isolate <= 1'b0;
      dst_isolate_ff <= 1'b0;
    end else begin
      dst_valid_sync <= dst_valid_i;
      dst_data_sync <= dst_data_o;
      dst_clear_sync <= dst_clear_i;
      dst_clear_ff <= dst_clear_i || (CLEAR_ON_ASYNC_RESET &&!dst_rst_ni);
      dst_clear_pending_ff <= dst_clear_i || dst_clear_pending_ff;
      dst_isolate <= dst_clear_i || dst_isolate_ff;
      dst_isolate_ff <= dst_clear_i || dst_isolate_ff;
    end
  end

  logic [SYNC_STAGES-1:0] src_valid_ff;
  logic [SYNC_STAGES-1:0] src_clear_ff_sync;
  logic [SYNC_STAGES-1:0] dst_valid_ff;
  logic [SYNC_STAGES-1:0] dst_clear_ff_sync;

  always_ff @(posedge src_clk_i) begin
    src_valid_ff[0] <= src_valid_sync;
    for (int i = 1; i < SYNC_STAGES; i++) begin
      src_valid_ff[i] <= src_valid_ff[i-1];
    end
    src_clear_ff_sync[0] <= src_clear_sync;
    for (int i = 1; i < SYNC_STAGES; i++) begin
      src_clear_ff_sync[i] <= src_clear_ff_sync[i-1];
    end
  end

  always_ff @(posedge dst_clk_i) begin
    dst_valid_ff[0] <= dst_valid_sync;
    for (int i = 1; i < SYNC_STAGES; i++) begin
      dst_valid_ff[i] <= dst_valid_ff[i-1];
    end
    dst_clear_ff_sync[0] <= dst_clear_sync;
    for (int i = 1; i < SYNC_STAGES; i++) begin
      dst_clear_ff_sync[i] <= dst_clear_ff_sync[i-1];
    end
  end

  assign src_ready_o =!src_isolate &&!src_clear_pending_ff && (dst_ready_i ||!dst_valid_sync);
  assign dst_valid_o =!dst_isolate &&!dst_clear_pending_ff && src_valid_sync;
  assign dst_data_o = src_data_sync;
  assign src_clear_pending_o = src_clear_pending_ff;
  assign dst_clear_pending_o = dst_clear_pending_ff;

endmodule
