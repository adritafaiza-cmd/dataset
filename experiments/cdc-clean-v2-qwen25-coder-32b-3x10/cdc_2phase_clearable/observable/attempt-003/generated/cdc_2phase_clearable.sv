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

  // Synchronization flops for clear signal
  logic [SYNC_STAGES-1:0] src_clear_sync;
  logic [SYNC_STAGES-1:0] dst_clear_sync;

  // Synchronization flops for valid signal
  logic [SYNC_STAGES-1:0] src_valid_sync;
  logic [SYNC_STAGES-1:0] dst_valid_sync;

  // Data storage
  logic [WIDTH-1:0] data_ff;

  // Control signals
  logic src_clear_active, dst_clear_active;
  logic src_valid_active, dst_valid_active;
  logic src_ready, dst_ready;

  // Synchronize clear signals
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

  // Synchronize valid signals
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_sync <= '0;
    end else begin
      src_valid_sync <= {src_valid_sync[SYNC_STAGES-2:0], src_valid_i};
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_sync <= '0;
    end else begin
      dst_valid_sync <= {dst_valid_sync[SYNC_STAGES-2:0], dst_valid_active};
    end
  end

  // Active clear signals
  assign src_clear_active = src_clear_sync[SYNC_STAGES-1];
  assign dst_clear_active = dst_clear_sync[SYNC_STAGES-1];

  // Active valid signals
  assign src_valid_active = src_valid_sync[SYNC_STAGES-1];
  assign dst_valid_active = dst_valid_sync[SYNC_STAGES-1];

  // Source side logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready <= 1'b0;
      src_clear_pending_o <= 1'b0;
    end else begin
      if (src_clear_active) begin
        src_ready <= 1'b0;
        src_clear_pending_o <= 1'b1;
      end else if (src_clear_pending_o && dst_clear_active) begin
        src_clear_pending_o <= 1'b0;
      end else begin
        src_ready <= dst_ready_i && !src_clear_pending_o;
      end
    end
  end

  // Destination side logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_o <= 1'b0;
      dst_clear_pending_o <= 1'b0;
    end else begin
      if (dst_clear_active) begin
        dst_valid_o <= 1'b0;
        dst_clear_pending_o <= 1'b1;
      end else if (dst_clear_pending_o && src_clear_active) begin
        dst_clear_pending_o <= 1'b0;
      end else begin
        dst_valid_o <= src_valid_active && !dst_clear_pending_o;
      end
    end
  end

  // Data transfer
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      data_ff <= '0;
    end else if (src_ready && src_valid_i) begin
      data_ff <= src_data_i;
    end
  end

  assign dst_data_o = data_ff;

endmodule
