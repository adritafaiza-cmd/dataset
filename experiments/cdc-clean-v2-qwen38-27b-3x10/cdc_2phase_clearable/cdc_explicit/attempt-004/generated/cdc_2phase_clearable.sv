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
  wire src_req;
  wire dst_ack;
  wire dst_req;
  wire src_ack;

  // Source domain: request generation
  reg src_req_reg;
  reg src_data_reg [WIDTH-1:0];
  reg src_valid_reg;
  reg src_clear_pending_reg;
  reg src_clear_active_reg;

  // Destination domain: acknowledge generation
  reg dst_ack_reg;
  reg dst_data_reg [WIDTH-1:0];
  reg dst_valid_reg;
  reg dst_clear_pending_reg;
  reg dst_clear_active_reg;

  // Synchronization signals
  wire src_req_synced;
  wire dst_ack_synced;
  wire dst_req_synced;
  wire src_ack_synced;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_req_reg <= 1'b0;
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_clear_pending_reg <= 1'b0;
      src_clear_active_reg <= 1'b0;
    end else begin
      if (src_clear_i) begin
        src_clear_active_reg <= 1'b1;
        src_clear_pending_reg <= 1'b1;
      end

      if (src_clear_active_reg) begin
        // During clear, isolate the channel
        src_req_reg <= 1'b0;
        src_valid_reg <= 1'b0;
        if (dst_ack_synced == 1'b0) begin
          // Clear complete when ack returns to 0
          src_clear_active_reg <= 1'b0;
          src_clear_pending_reg <= 1'b0;
        end
      end else begin
        // Normal operation
        if (src_valid_i && !src_req_reg) begin
          src_req_reg <= 1'b1;
          src_data_reg <= src_data_i;
          src_valid_reg <= 1'b1;
        end
        if (dst_ack_synced) begin
          src_req_reg <= 1'b0;
          src_valid_reg <= 1'b0;
        end
      end
    end
  end

  assign src_ready_o = !src_req_reg && !src_clear_active_reg;
  assign src_clear_pending_o = src_clear_pending_reg;

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ack_reg <= 1'b0;
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      dst_clear_pending_reg <= 1'b0;
      dst_clear_active_reg <= 1'b0;
    end else begin
      if (dst_clear_i) begin
        dst_clear_active_reg <= 1'b1;
        dst_clear_pending_reg <= 1'b1;
      end

      if (dst_clear_active_reg) begin
        // During clear, isolate the channel
        dst_ack_reg <= 1'b0;
        dst_valid_reg <= 1'b0;
        if (src_ack_synced == 1'b0) begin
          // Clear complete when ack returns to 0
          dst_clear_active_reg <= 1'b0;
          dst_clear_pending_reg <= 1'b0;
        end
      end else begin
        // Normal operation
        if (src_req_synced && !dst_ack_reg) begin
          dst_ack_reg <= 1'b1;
          dst_data_reg <= src_data_synced;
          dst_valid_reg <= 1'b1;
        end
        if (dst_ack_reg && dst_ready_i) begin
          dst_ack_reg <= 1'b0;
          dst_valid_reg <= 1'b0;
        end
      end
    end
  end

  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_clear_pending_o = dst_clear_pending_reg;

  // Synchronization of src_req to dst domain
  reg [SYNC_STAGES-1:0] src_req_sync;
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_req_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      src_req_sync <= {src_req_sync[SYNC_STAGES-2:0], src_req};
    end
  end
  assign src_req_synced = src_req_sync[SYNC_STAGES-1];

  // Synchronization of dst_ack to src domain
  reg [SYNC_STAGES-1:0] dst_ack_sync;
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ack_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_ack_sync <= {dst_ack_sync[SYNC_STAGES-2:0], dst_ack};
    end
  end
  assign dst_ack_synced = dst_ack_sync[SYNC_STAGES-1];

  // Synchronization of dst_req to src domain (for clear coordination)
  // dst_req is implicitly the dst_ack_reg when in clear mode
  // We need to synchronize dst_ack to src for clear completion
  // Already done above with dst_ack_sync

  // Synchronization of src_ack to dst domain (for clear coordination)
  // src_ack is implicitly the src_req_reg when in clear mode
  // We need to synchronize src_req to dst for clear completion
  // Already done above with src_req_sync

  // Synchronization of src_data to dst domain
  // Data must be stable when src_req is high
  reg [SYNC_STAGES-1:0][WIDTH-1:0] src_data_sync;
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      for (int i = 0; i < SYNC_STAGES; i = i + 1) begin
        src_data_sync[i] <= {WIDTH{1'b0}};
      end
    end else begin
      src_data_sync[0] <= src_data_reg;
      for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
        src_data_sync[i] <= src_data_sync[i-1];
      end
    end
  end
  wire [WIDTH-1:0] src_data_synced = src_data_sync[SYNC_STAGES-1];

endmodule
