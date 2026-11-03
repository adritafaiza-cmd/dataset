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
  logic src_valid_synced;
  logic [WIDTH-1:0] src_data_synced;
  logic src_clear_synced;
  logic dst_clear_synced;
  logic src_ready;
  logic dst_valid;
  logic src_clear_pending;
  logic dst_clear_pending;
  logic clear_active;
  logic clear_active_synced;

  // Sync signals across clock domains
  logic [SYNC_STAGES-1:0] src_valid_sync;
  logic [SYNC_STAGES-1:0] src_clear_sync;
  logic [SYNC_STAGES-1:0] dst_clear_sync;

  // Source side logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready <= 1'b0;
      src_clear_pending <= 1'b0;
      clear_active <= 1'b0;
    end else begin
      if (clear_active && !src_clear_synced) begin
        clear_active <= 1'b0;
      end else if (src_clear_i) begin
        clear_active <= 1'b1;
        src_clear_pending <= 1'b1;
      end

      if (clear_active) begin
        src_ready <= 1'b0;
      end else if (src_valid_i && src_ready) begin
        src_ready <= 1'b0;
      end else if (!src_valid_i && !src_ready) begin
        src_ready <= 1'b1;
      end

      if (src_clear_synced) begin
        src_clear_pending <= 1'b0;
      end
    end
  end

  // Destination side logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid <= 1'b0;
      dst_clear_pending <= 1'b0;
    end else begin
      if (dst_clear_synced) begin
        dst_valid <= 1'b0;
        dst_clear_pending <= 1'b0;
      end else if (src_valid_synced && !dst_valid) begin
        dst_valid <= 1'b1;
      end else if (dst_valid && dst_ready_i) begin
        dst_valid <= 1'b0;
      end

      if (dst_clear_i) begin
        dst_clear_pending <= 1'b1;
      end
    end
  end

  // Data synchronization
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o <= '0;
    end else if (src_valid_synced) begin
      dst_data_o <= src_data_synced;
    end
  end

  // Sync signals across clock domains
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_sync <= '0;
    end else begin
      src_valid_sync <= {src_valid_sync[SYNC_STAGES-2:0], src_valid_i};
    end
  end

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_sync <= '0;
    end else begin
      src_clear_sync <= {src_clear_sync[SYNC_STAGES-2:0], src_clear_i};
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_sync <= '0;
    end else begin
      dst_clear_sync <= {dst_clear_sync[SYNC_STAGES-2:0], dst_clear_i};
    end
  end

  // Assign synced signals
  assign src_valid_synced = src_valid_sync[SYNC_STAGES-1];
  assign src_clear_synced = src_clear_sync[SYNC_STAGES-1];
  assign dst_clear_synced = dst_clear_sync[SYNC_STAGES-1];

  // Assign outputs
  assign src_ready_o = src_ready;
  assign src_clear_pending_o = src_clear_pending;
  assign dst_clear_pending_o = dst_clear_pending;
  assign dst_valid_o = dst_valid;

endmodule
