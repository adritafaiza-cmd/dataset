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
  reg  src_valid_sync;
  reg  dst_valid_sync;
  reg  src_clear_sync;
  reg  dst_clear_sync;
  reg  clear_request;
  reg  clear_ack;
  reg  src_clear_pending;
  reg  dst_clear_pending;
  reg  src_ready;
  reg  dst_valid;

  // Synchronizers
  reg [SYNC_STAGES-1:0] src_valid_sync_ff;
  reg [SYNC_STAGES-1:0] dst_valid_sync_ff;
  reg [SYNC_STAGES-1:0] src_clear_sync_ff;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ff;

  // Source-domain synchronizers
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_sync_ff <= 0;
      src_clear_sync_ff <= 0;
    end else begin
      src_valid_sync_ff <= {src_valid_sync_ff[SYNC_STAGES-2:0], src_valid_i};
      src_clear_sync_ff <= {src_clear_sync_ff[SYNC_STAGES-2:0], src_clear_i};
    end
  end

  // Destination-domain synchronizers
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_sync_ff <= 0;
      dst_clear_sync_ff <= 0;
    end else begin
      dst_valid_sync_ff <= {dst_valid_sync_ff[SYNC_STAGES-2:0], dst_valid_sync};
      dst_clear_sync_ff <= {dst_clear_sync_ff[SYNC_STAGES-2:0], dst_clear_i};
    end
  end

  // Synchronized signals
  assign src_valid_sync = src_valid_sync_ff[SYNC_STAGES-1];
  assign src_clear_sync = src_clear_sync_ff[SYNC_STAGES-1];
  assign dst_valid_sync = dst_valid_sync_ff[SYNC_STAGES-1];
  assign dst_clear_sync = dst_clear_sync_ff[SYNC_STAGES-1];

  // Source-side logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready <= 0;
      src_clear_pending <= 0;
      clear_request <= 0;
    end else begin
      // Clear request and pending logic
      if (src_clear_i) begin
        src_clear_pending <= 1;
        clear_request <= 1;
      end else if (clear_ack) begin
        src_clear_pending <= 0;
      end

      // Ready logic
      if (clear_request || src_clear_pending || !dst_ready_i || dst_clear_sync) begin
        src_ready <= 0;
      end else if (src_valid_i) begin
        src_ready <= 1;
      end
    end
  end

  // Destination-side logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid <= 0;
      dst_clear_pending <= 0;
      clear_ack <= 0;
      dst_data_o <= 0;
    end else begin
      // Clear acknowledge and pending logic
      if (dst_clear_i) begin
        dst_clear_pending <= 1;
      end else if (clear_request) begin
        dst_clear_pending <= 0;
        clear_ack <= 1;
      end else if (dst_ready_i && dst_valid) begin
        clear_ack <= 0;
      end

      // Valid and data logic
      if (dst_clear_i || dst_clear_sync) begin
        dst_valid <= 0;
        dst_data_o <= 0;
      end else if (src_valid_sync && src_ready) begin
        dst_valid <= 1;
        dst_data_o <= src_data_i;
      end else if (dst_ready_i && dst_valid) begin
        dst_valid <= 0;
      end
    end
  end

  // Outputs
  assign src_clear_pending_o = src_clear_pending;
  assign src_ready_o = src_ready;
  assign dst_clear_pending_o = dst_clear_pending;
  assign dst_valid_o = dst_valid;

endmodule
