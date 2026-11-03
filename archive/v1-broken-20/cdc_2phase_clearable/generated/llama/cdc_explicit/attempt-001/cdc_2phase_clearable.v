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
  logic src_data_sync_ff;
  logic src_clear_sync;
  logic src_clear_sync_ff;
  logic src_clear_pending;
  logic src_clear_pending_ff;
  logic src_ready;
  logic src_ready_ff;

  logic dst_valid_sync;
  logic dst_valid_sync_ff;
  logic [WIDTH-1:0] dst_data_sync;
  logic [WIDTH-1:0] dst_data_sync_ff;
  logic dst_clear_sync;
  logic dst_clear_sync_ff;
  logic dst_clear_pending;
  logic dst_clear_pending_ff;
  logic dst_valid;
  logic dst_valid_ff;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_sync <= 1'b0;
      src_data_sync <= '0;
      src_clear_sync <= 1'b0;
      src_clear_pending <= 1'b0;
      src_ready <= 1'b0;
    end else begin
      src_valid_sync <= src_valid_i;
      src_data_sync <= src_data_i;
      src_clear_sync <= src_clear_i;
      src_clear_pending <= src_clear_pending_ff;
      src_ready <= src_ready_ff;
    end
  end

  always_comb begin
    src_ready_ff = (src_clear_pending || src_clear_sync)? 1'b0 : (src_valid_sync && src_valid_i)? 1'b1 : 1'b0;
    src_clear_pending_ff = (src_clear_pending &&!src_clear_sync) || (src_clear_sync &&!src_clear_pending);
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_sync <= 1'b0;
      dst_data_sync <= '0;
      dst_clear_sync <= 1'b0;
      dst_clear_pending <= 1'b0;
      dst_valid <= 1'b0;
    end else begin
      dst_valid_sync <= dst_valid_i;
      dst_data_sync <= dst_data_i;
      dst_clear_sync <= dst_clear_i;
      dst_clear_pending <= dst_clear_pending_ff;
      dst_valid <= dst_valid_ff;
    end
  end

  always_comb begin
    dst_valid_ff = (dst_clear_pending || dst_clear_sync)? 1'b0 : (dst_valid_sync && dst_valid_i)? 1'b1 : 1'b0;
    dst_clear_pending_ff = (dst_clear_pending &&!dst_clear_sync) || (dst_clear_sync &&!dst_clear_pending);
  end

  // CDC
  logic [SYNC_STAGES-1:0] src_valid_sync_chain;
  logic [SYNC_STAGES-1:0] src_clear_sync_chain;
  logic [SYNC_STAGES-1:0] dst_valid_sync_chain;
  logic [SYNC_STAGES-1:0] dst_clear_sync_chain;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_sync_chain <= '0;
      src_clear_sync_chain <= '0;
    end else begin
      src_valid_sync_chain[0] <= src_valid_sync;
      src_clear_sync_chain[0] <= src_clear_sync;
      for (int i = 1; i < SYNC_STAGES; i++) begin
        src_valid_sync_chain[i] <= src_valid_sync_chain[i-1];
        src_clear_sync_chain[i] <= src_clear_sync_chain[i-1];
      end
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_sync_chain <= '0;
      dst_clear_sync_chain <= '0;
    end else begin
      dst_valid_sync_chain[0] <= dst_valid_sync;
      dst_clear_sync_chain[0] <= dst_clear_sync;
      for (int i = 1; i < SYNC_STAGES; i++) begin
        dst_valid_sync_chain[i] <= dst_valid_sync_chain[i-1];
        dst_clear_sync_chain[i] <= dst_clear_sync_chain[i-1];
      end
    end
  end

  assign src_clear_pending_o = src_clear_pending;
  assign src_ready_o = src_ready;
  assign dst_clear_pending_o = dst_clear_pending;
  assign dst_data_o = dst_data_sync;
  assign dst_valid_o = dst_valid;

endmodule
