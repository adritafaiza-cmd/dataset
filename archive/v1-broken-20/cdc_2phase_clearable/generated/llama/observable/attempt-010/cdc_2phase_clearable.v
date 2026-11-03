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
  logic src_valid_synced_r;
  logic [WIDTH-1:0] src_data_synced;
  logic [WIDTH-1:0] src_data_synced_r;
  logic src_clear_synced;
  logic src_clear_synced_r;
  logic dst_valid_synced;
  logic dst_valid_synced_r;
  logic [WIDTH-1:0] dst_data_synced;
  logic [WIDTH-1:0] dst_data_synced_r;
  logic dst_clear_synced;
  logic dst_clear_synced_r;

  logic src_valid_pulse;
  logic src_valid_pulse_r;
  logic src_clear_pulse;
  logic src_clear_pulse_r;
  logic dst_valid_pulse;
  logic dst_valid_pulse_r;
  logic dst_clear_pulse;
  logic dst_clear_pulse_r;

  logic src_valid_handshake;
  logic src_valid_handshake_r;
  logic dst_valid_handshake;
  logic dst_valid_handshake_r;

  logic src_clear_pending;
  logic dst_clear_pending;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
      src_valid_synced_r <= 1'b0;
      src_data_synced_r <= '0;
      src_clear_synced_r <= 1'b0;
      src_valid_pulse_r <= 1'b0;
      src_clear_pulse_r <= 1'b0;
      src_valid_handshake_r <= 1'b0;
    end else begin
      src_valid_synced_r <= src_valid_synced;
      src_data_synced_r <= src_data_synced;
      src_clear_synced_r <= src_clear_synced;
      src_valid_pulse_r <= src_valid_pulse;
      src_clear_pulse_r <= src_clear_pulse;
      src_valid_handshake_r <= src_valid_handshake;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
      dst_valid_synced_r <= 1'b0;
      dst_data_synced_r <= '0;
      dst_clear_synced_r <= 1'b0;
      dst_valid_pulse_r <= 1'b0;
      dst_clear_pulse_r <= 1'b0;
      dst_valid_handshake_r <= 1'b0;
    end else begin
      dst_valid_synced_r <= dst_valid_synced;
      dst_data_synced_r <= dst_data_synced;
      dst_clear_synced_r <= dst_clear_synced;
      dst_valid_pulse_r <= dst_valid_pulse;
      dst_clear_pulse_r <= dst_clear_pulse;
      dst_valid_handshake_r <= dst_valid_handshake;
    end
  end

  assign src_clear_pending_o = src_clear_pending;
  assign dst_clear_pending_o = dst_clear_pending;

  assign src_valid_pulse = src_valid_i && ~src_valid_handshake_r;
  assign src_clear_pulse = src_clear_i && ~src_clear_synced_r;

  assign dst_valid_pulse = dst_valid_synced && ~dst_valid_handshake_r;
  assign dst_clear_pulse = dst_clear_i && ~dst_clear_synced_r;

  assign src_valid_handshake = src_valid_synced_r && src_ready_o;
  assign dst_valid_handshake = dst_valid_synced_r && dst_ready_i;

  assign src_ready_o = ~src_valid_synced_r || dst_valid_handshake_r;
  assign dst_valid_o = dst_valid_synced_r;
  assign dst_data_o = dst_data_synced_r;

  always_comb begin
    src_valid_synced = 1'b0;
    src_data_synced = '0;
    src_clear_synced = 1'b0;
    if (~src_clear_pending) begin
      if (src_valid_pulse) begin
        src_valid_synced = 1'b1;
        src_data_synced = src_data_i;
      end
      if (src_clear_pulse) begin
        src_clear_synced = 1'b1;
      end
    end
  end

  always_comb begin
    dst_valid_synced = 1'b0;
    dst_data_synced = '0;
    dst_clear_synced = 1'b0;
    if (~dst_clear_pending) begin
      if (dst_valid_pulse) begin
        dst_valid_synced = 1'b1;
        dst_data_synced = dst_data_synced_r;
      end
      if (dst_clear_pulse) begin
        dst_clear_synced = 1'b1;
      end
    end
  end

  always_ff @(posedge src_clk_i) begin
    if (src_clear_synced_r) begin
      src_clear_pending <= 1'b1;
    end else if (dst_clear_synced_r) begin
      src_clear_pending <= 1'b0;
    end
  end

  always_ff @(posedge dst_clk_i) begin
    if (dst_clear_synced_r) begin
      dst_clear_pending <= 1'b1;
    end else if (src_clear_synced_r) begin
      dst_clear_pending <= 1'b0;
    end
  end

  // CDC for src_valid_synced
  logic [SYNC_STAGES-1:0] src_valid_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
      src_valid_sync <= '0;
    end else begin
      src_valid_sync[0] <= src_valid_synced;
      for (int i = 1; i < SYNC_STAGES; i++) begin
        src_valid_sync[i] <= src_valid_sync[i-1];
      end
    end
  end
  assign dst_valid_synced = src_valid_sync[SYNC_STAGES-1];

  // CDC for src_data_synced
  logic [WIDTH-1:0] src_data_sync [SYNC_STAGES-1:0];
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
      src_data_sync <= '0;
    end else begin
      src_data_sync[0] <= src_data_synced;
      for (int i = 1; i < SYNC_STAGES; i++) begin
        src_data_sync[i] <= src_data_sync[i-1];
      end
    end
  end
  assign dst_data_synced = src_data_sync[SYNC_STAGES-1];

  // CDC for src_clear_synced
  logic [SYNC_STAGES-1:0] src_clear_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
      src_clear_sync <= '0;
    end else begin
      src_clear_sync[0] <= src_clear_synced;
      for (int i = 1; i < SYNC_STAGES; i++) begin
        src_clear_sync[i] <= src_clear_sync[i-1];
      end
    end
  end
  assign dst_clear_synced = src_clear_sync[SYNC_STAGES-1];

  // CDC for dst_valid_synced
  logic [SYNC_STAGES-1:0] dst_valid_sync;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
      dst_valid_sync <= '0;
    end else begin
      dst_valid_sync[0] <= dst_valid_synced;
      for (int i = 1; i < SYNC_STAGES; i++) begin
        dst_valid_sync[i] <= dst_valid_sync[i-1];
      end
    end
  end
  assign src_valid_handshake = dst_valid_sync[SYNC_STAGES-1];

  // CDC for dst_clear_synced
  logic [SYNC_STAGES-1:0] dst_clear_sync;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
      dst_clear_sync <= '0;
    end else begin
      dst_clear_sync[0] <= dst_clear_synced;
      for (int i = 1; i < SYNC_STAGES; i++) begin
        dst_clear_sync[i] <= dst_clear_sync[i-1];
      end
    end
  end
  assign src_clear_pending = dst_clear_sync[SYNC_STAGES-1];

endmodule
