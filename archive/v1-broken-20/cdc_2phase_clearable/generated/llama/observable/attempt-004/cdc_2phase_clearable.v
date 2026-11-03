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
  logic src_clear_sync;
  logic [WIDTH-1:0] src_data_sync;
  logic dst_valid_sync;
  logic dst_clear_sync;
  logic [WIDTH-1:0] dst_data_sync;

  logic src_valid_ff;
  logic src_clear_ff;
  logic [WIDTH-1:0] src_data_ff;
  logic dst_valid_ff;
  logic dst_clear_ff;
  logic [WIDTH-1:0] dst_data_ff;

  logic src_valid_pulse;
  logic src_clear_pulse;
  logic dst_valid_pulse;
  logic dst_clear_pulse;

  logic src_clear_pending;
  logic dst_clear_pending;

  assign src_clear_pending_o = src_clear_pending;
  assign dst_clear_pending_o = dst_clear_pending;

  // Source clock domain
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_ff <= 1'b0;
      src_clear_ff <= 1'b0;
      src_data_ff <= '0;
      src_clear_pending <= 1'b0;
    end else if (src_clear_i) begin
      src_valid_ff <= 1'b0;
      src_clear_ff <= 1'b1;
      src_data_ff <= '0;
      src_clear_pending <= 1'b1;
    end else if (src_valid_i &&!src_valid_ff) begin
      src_valid_ff <= 1'b1;
      src_data_ff <= src_data_i;
      src_clear_pending <= 1'b0;
    end else if (!src_valid_i && src_valid_ff) begin
      src_valid_ff <= 1'b0;
      src_clear_pending <= 1'b0;
    end
  end

  assign src_valid_sync = src_valid_ff;
  assign src_clear_sync = src_clear_ff;
  assign src_data_sync = src_data_ff;

  assign src_ready_o =!src_valid_ff;

  // Synchronization to destination clock domain
  logic [SYNC_STAGES-1:0] src_valid_sync_ff;
  logic [SYNC_STAGES-1:0] src_clear_sync_ff;
  logic [SYNC_STAGES-1:0] [WIDTH-1:0] src_data_sync_ff;

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync_ff <= '0;
      src_clear_sync_ff <= '0;
      src_data_sync_ff <= '0;
    end else begin
      src_valid_sync_ff[0] <= src_valid_sync;
      src_clear_sync_ff[0] <= src_clear_sync;
      src_data_sync_ff[0] <= src_data_sync;
      for (int i = 1; i < SYNC_STAGES; i++) begin
        src_valid_sync_ff[i] <= src_valid_sync_ff[i-1];
        src_clear_sync_ff[i] <= src_clear_sync_ff[i-1];
        src_data_sync_ff[i] <= src_data_sync_ff[i-1];
      end
    end
  end

  assign dst_valid_sync = src_valid_sync_ff[SYNC_STAGES-1];
  assign dst_clear_sync = src_clear_sync_ff[SYNC_STAGES-1];
  assign dst_data_sync = src_data_sync_ff[SYNC_STAGES-1];

  // Destination clock domain
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_ff <= 1'b0;
      dst_clear_ff <= 1'b0;
      dst_data_ff <= '0;
      dst_clear_pending <= 1'b0;
    end else if (dst_clear_i) begin
      dst_valid_ff <= 1'b0;
      dst_clear_ff <= 1'b1;
      dst_data_ff <= '0;
      dst_clear_pending <= 1'b1;
    end else if (dst_valid_sync &&!dst_valid_ff) begin
      dst_valid_ff <= 1'b1;
      dst_data_ff <= dst_data_sync;
      dst_clear_pending <= 1'b0;
    end else if (!dst_valid_sync && dst_valid_ff) begin
      dst_valid_ff <= 1'b0;
      dst_clear_pending <= 1'b0;
    end
  end

  assign dst_valid_o = dst_valid_ff;
  assign dst_data_o = dst_data_ff;

  assign src_valid_pulse = src_valid_sync &&!src_valid_sync_ff[0];
  assign src_clear_pulse = src_clear_sync &&!src_clear_sync_ff[0];
  assign dst_valid_pulse = dst_valid_sync &&!dst_valid_ff;
  assign dst_clear_pulse = dst_clear_sync &&!dst_clear_ff;

  // Clear pulse synchronization to source clock domain
  logic [SYNC_STAGES-1:0] dst_clear_pulse_sync_ff;
  logic [SYNC_STAGES-1:0] dst_valid_pulse_sync_ff;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_clear_pulse_sync_ff <= '0;
      dst_valid_pulse_sync_ff <= '0;
    end else begin
      dst_clear_pulse_sync_ff[0] <= dst_clear_pulse;
      dst_valid_pulse_sync_ff[0] <= dst_valid_pulse;
      for (int i = 1; i < SYNC_STAGES; i++) begin
        dst_clear_pulse_sync_ff[i] <= dst_clear_pulse_sync_ff[i-1];
        dst_valid_pulse_sync_ff[i] <= dst_valid_pulse_sync_ff[i-1];
      end
    end
  end

  assign src_clear_pending <= dst_clear_pulse_sync_ff[SYNC_STAGES-1] || src_clear_pending;

endmodule
