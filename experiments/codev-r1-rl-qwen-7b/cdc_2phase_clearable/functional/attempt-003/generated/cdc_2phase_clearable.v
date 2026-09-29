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

  // Source domain clear synchronization
  reg [SYNC_STAGES-1:0] dst_clear_sync;
  wire dst_clear_synced;
  // Destination domain clear synchronization
  reg [SYNC_STAGES-1:0] src_clear_sync;
  wire src_clear_synced;

  // Source domain clear pending
  reg src_clear_pending;
  // Destination domain clear pending
  reg dst_clear_pending;

  // Two-phase handshake signals
  reg src_toggle;
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;

  // Synchronization registers for destination ready
  reg dst_ready_sync1, dst_ready_sync2;

  // Destination domain toggle synchronization
  reg dst_toggle_sync1, dst_toggle_sync2;
  reg dst_toggle_prev;

  // Synchronization registers for destination ready in source domain
  reg dst_ready_sync1_src, dst_ready_sync2_src;

  // Clear logic
  wire clear = src_clear_pending || dst_clear_pending;

  // Source domain clear synchronization
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_clear_sync <= 0;
    end else begin
      dst_clear_sync <= {dst_clear_sync[SYNC_STAGES-2:0], dst_clear_i};
    end
  end
  assign dst_clear_synced = dst_clear_sync[SYNC_STAGES-1];

  // Destination domain clear synchronization
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_clear_sync <= 0;
    end else begin
      src_clear_sync <= {src_clear_sync[SYNC_STAGES-2:0], src_clear_i};
    end
  end
  assign src_clear_synced = src_clear_sync[SYNC_STAGES-1];

  // Source clear pending
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pending <= 0;
    end else begin
      if (src_clear_i || dst_clear_synced)
        src_clear_pending <= 1;
      else if (src_clear_synced)
        src_clear_pending <= 0;
    end
  end

  // Destination clear pending
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pending <= 0;
    end else begin
      if (dst_clear_i || src_clear_synced)
        dst_clear_pending <= 1;
      else if (dst_clear_synced)
        dst_clear_pending <= 0;
    end
  end

  // Source domain ready and valid
  assign src_ready_o = dst_ready_sync2 && !src_valid_reg;

  // Two-phase handshake registers
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_toggle <= 0;
      src_data_reg <= 0;
      src_valid_reg <= 0;
    end else if (clear) begin
      src_toggle <= 0;
      src_data_reg <= 0;
      src_valid_reg <= 0;
    end else if (src_valid_i && src_ready_o) begin
      src_data_reg <= src_data_i;
      src_valid_reg <= 1;
      src_toggle <= ~src_toggle;
    end else if (dst_ready_sync2) begin
      src_valid_reg <= 0;
    end
  end

  // Synchronize destination's ready to source domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_sync1 <= 0;
      dst_ready_sync2 <= 0;
    end else begin
      dst_ready_sync1 <= dst_ready_i;
      dst_ready_sync2 <= dst_ready_sync1;
    end
  end

  // Synchronize source's toggle to destination domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_toggle_sync1 <= 0;
      dst_toggle_sync2 <= 0;
    end else begin
      dst_toggle_sync1 <= src_toggle;
      dst_toggle_sync2 <= dst_toggle_sync1;
    end
  end

  // Destination valid and data
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_toggle_prev <= 0;
    end else begin
      dst_toggle_prev <= dst_toggle_sync2;
    end
  end

  assign dst_valid_o = (dst_toggle_prev != dst_toggle_sync2);
  assign dst_data_o = src_data_reg;

  // Synchronize destination's ready to source domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_sync1_src <= 0;
      dst_ready_sync2_src <= 0;
    end else begin
      dst_ready_sync1_src <= dst_ready_i;
      dst_ready_sync2_src <= dst_ready_sync1_src;
    end
  end

  // Output clear pending signals
  assign src_clear_pending_o = src_clear_pending;
  assign dst_clear_pending_o = dst_clear_pending;

endmodule
