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
  logic src_valid_sync_r;
  logic [WIDTH-1:0] src_data_sync;
  logic [WIDTH-1:0] src_data_sync_r;
  logic src_clear_sync;
  logic src_clear_sync_r;
  logic dst_clear_sync;
  logic dst_clear_sync_r;
  logic src_valid_dst;
  logic src_valid_dst_r;
  logic [WIDTH-1:0] src_data_dst;
  logic [WIDTH-1:0] src_data_dst_r;
  logic dst_valid;
  logic dst_valid_r;
  logic src_ready;
  logic src_ready_r;
  logic dst_ready_sync;
  logic dst_ready_sync_r;
  logic src_clear_pending;
  logic dst_clear_pending;

  assign src_clear_pending_o = src_clear_pending;
  assign dst_clear_pending_o = dst_clear_pending;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_sync <= 1'b0;
      src_data_sync <= '0;
      src_clear_sync <= 1'b0;
      src_ready <= 1'b0;
      src_clear_pending <= 1'b0;
    end else begin
      src_valid_sync <= src_valid_i;
      src_data_sync <= src_data_i;
      src_clear_sync <= src_clear_i;
      src_ready <= (src_valid_sync && src_clear_sync) ? 1'b0 : (src_valid_sync && !src_clear_sync) ? 1'b1 : src_ready_r;
      src_clear_pending <= (src_clear_i && !src_clear_pending) ? 1'b1 : (src_clear_sync && src_valid_sync && !src_clear_pending) ? 1'b0 : src_clear_pending;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid <= 1'b0;
      dst_data_o <= '0;
      dst_clear_pending <= 1'b0;
    end else begin
      dst_valid <= (dst_valid_r && !dst_ready_i) ? 1'b1 : (src_valid_dst && !dst_clear_sync) ? 1'b1 : 1'b0;
      dst_data_o <= (src_valid_dst && !dst_clear_sync) ? src_data_dst : dst_data_o;
      dst_clear_pending <= (dst_clear_i && !dst_clear_pending) ? 1'b1 : (dst_clear_sync && dst_valid && !dst_clear_pending) ? 1'b0 : dst_clear_pending;
    end
  end

  always_ff @(posedge src_clk_i) begin
    src_valid_sync_r <= src_valid_sync;
    src_data_sync_r <= src_data_sync;
    src_clear_sync_r <= src_clear_sync;
    src_ready_r <= src_ready;
  end

  always_ff @(posedge dst_clk_i) begin
    dst_valid_r <= dst_valid;
    src_valid_dst_r <= src_valid_dst;
    src_data_dst_r <= src_data_dst;
    dst_clear_sync_r <= dst_clear_sync;
    dst_ready_sync_r <= dst_ready_i;
  end

  // Synchronization of src_valid and src_data
  logic [SYNC_STAGES-1:0] src_valid_sync_pipe;
  logic [SYNC_STAGES-1:0] [WIDTH-1:0] src_data_sync_pipe;

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync_pipe <= '0;
      src_data_sync_pipe <= '0;
    end else begin
      src_valid_sync_pipe[0] <= src_valid_sync;
      src_data_sync_pipe[0] <= src_data_sync;
      for (int i = 1; i < SYNC_STAGES; i++) begin
        src_valid_sync_pipe[i] <= src_valid_sync_pipe[i-1];
        src_data_sync_pipe[i] <= src_data_sync_pipe[i-1];
      end
    end
  end

  assign src_valid_dst = src_valid_sync_pipe[SYNC_STAGES-1];
  assign src_data_dst = src_data_sync_pipe[SYNC_STAGES-1];

  // Synchronization of dst_ready
  logic [SYNC_STAGES-1:0] dst_ready_sync_pipe;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_sync_pipe <= '0;
    end else begin
      dst_ready_sync_pipe[0] <= dst_ready_i;
      for (int i = 1; i < SYNC_STAGES; i++) begin
        dst_ready_sync_pipe[i] <= dst_ready_sync_pipe[i-1];
      end
    end
  end

  assign dst_ready_sync = dst_ready_sync_pipe[SYNC_STAGES-1];

  // Synchronization of src_clear and dst_clear
  logic [SYNC_STAGES-1:0] src_clear_sync_pipe;
  logic [SYNC_STAGES-1:0] dst_clear_sync_pipe;

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_clear_sync_pipe <= '0;
    end else begin
      src_clear_sync_pipe[0] <= src_clear_sync;
      for (int i = 1; i < SYNC_STAGES; i++) begin
        src_clear_sync_pipe[i] <= src_clear_sync_pipe[i-1];
      end
    end
  end

  assign dst_clear_sync = src_clear_sync_pipe[SYNC_STAGES-1];

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_clear_sync_pipe <= '0;
    end else begin
      dst_clear_sync_pipe[0] <= dst_clear_i;
      for (int i = 1; i < SYNC_STAGES; i++) begin
        dst_clear_sync_pipe[i] <= dst_clear_sync_pipe[i-1];
      end
    end
  end

  assign src_clear_sync_r = dst_clear_sync_pipe[SYNC_STAGES-1];

  assign dst_valid_o = dst_valid;

endmodule
