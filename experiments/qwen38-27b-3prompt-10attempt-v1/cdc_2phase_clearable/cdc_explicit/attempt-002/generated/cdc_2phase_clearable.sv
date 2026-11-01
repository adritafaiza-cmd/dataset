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
  wire src_clear_active;
  wire dst_clear_active;
  wire src_clear_synced;
  wire dst_clear_synced;
  wire src_clear_ack;
  wire dst_clear_ack;
  wire src_clear_done;
  wire dst_clear_done;

  // Clear pending logic
  reg src_clear_pending_r;
  reg dst_clear_pending_r;

  // Source domain: handshake state
  reg src_valid_r;
  reg [WIDTH-1:0] src_data_r;
  wire src_ready_internal;

  // Destination domain: handshake state
  reg dst_valid_r;
  reg [WIDTH-1:0] dst_data_r;
  wire dst_ready_internal;

  // CDC synchronizers for clear signals
  // src_clear_i -> dst domain
  reg [SYNC_STAGES-1:0] src_clear_sync_r;
  // dst_clear_i -> src domain
  reg [SYNC_STAGES-1:0] dst_clear_sync_r;

  // Clear acknowledgment signals
  // src_clear_ack: src tells dst that src has cleared
  reg src_clear_ack_r;
  reg [SYNC_STAGES-1:0] src_clear_ack_sync_r;
  // dst_clear_ack: dst tells src that dst has cleared
  reg dst_clear_ack_r;
  reg [SYNC_STAGES-1:0] dst_clear_ack_sync_r;

  // Clear done signals
  wire src_clear_done_internal;
  wire dst_clear_done_internal;

  // Assign outputs
  assign src_clear_pending_o = src_clear_pending_r;
  assign dst_clear_pending_o = dst_clear_pending_r;
  assign src_ready_o = src_ready_internal & ~src_clear_pending_r;
  assign dst_valid_o = dst_valid_r & ~dst_clear_pending_r;
  assign dst_data_o = dst_data_r;

  // Clear active signals
  assign src_clear_active = src_clear_i | (CLEAR_ON_ASYNC_RESET ? ~src_rst_ni : 1'b0);
  assign dst_clear_active = dst_clear_i | (CLEAR_ON_ASYNC_RESET ? ~dst_rst_ni : 1'b0);

  // Synchronize src_clear_i to dst domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      src_clear_sync_r <= {SYNC_STAGES{1'b0}};
    else
      src_clear_sync_r <= {src_clear_sync_r[SYNC_STAGES-2:0], src_clear_active};
  end
  assign src_clear_synced = src_clear_sync_r[SYNC_STAGES-1];

  // Synchronize dst_clear_i to src domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      dst_clear_sync_r <= {SYNC_STAGES{1'b0}};
    else
      dst_clear_sync_r <= {dst_clear_sync_r[SYNC_STAGES-2:0], dst_clear_active};
  end
  assign dst_clear_synced = dst_clear_sync_r[SYNC_STAGES-1];

  // Source domain: clear pending management
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      src_clear_pending_r <= 1'b0;
    else if (src_clear_active)
      src_clear_pending_r <= 1'b1;
    else if (src_clear_pending_r && src_clear_done_internal)
      src_clear_pending_r <= 1'b0;
  end

  // Destination domain: clear pending management
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      dst_clear_pending_r <= 1'b0;
    else if (dst_clear_active)
      dst_clear_pending_r <= 1'b1;
    else if (dst_clear_pending_r && dst_clear_done_internal)
      dst_clear_pending_r <= 1'b0;
  end

  // Source domain: clear acknowledgment
  // src_clear_ack_r is set when src has finished clearing and tells dst
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      src_clear_ack_r <= 1'b0;
    else if (src_clear_active)
      src_clear_ack_r <= 1'b0;
    else if (src_clear_pending_r && src_clear_done_internal)
      src_clear_ack_r <= 1'b1;
    else if (!src_clear_pending_r)
      src_clear_ack_r <= 1'b0;
  end

  // Synchronize src_clear_ack_r to dst domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      src_clear_ack_sync_r <= {SYNC_STAGES{1'b0}};
    else
      src_clear_ack_sync_r <= {src_clear_ack_sync_r[SYNC_STAGES-2:0], src_clear_ack_r};
  end
  assign src_clear_ack = src_clear_ack_sync_r[SYNC_STAGES-1];

  // Destination domain: clear acknowledgment
  // dst_clear_ack_r is set when dst has finished clearing and tells src
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      dst_clear_ack_r <= 1'b0;
    else if (dst_clear_active)
      dst_clear_ack_r <= 1'b0;
    else if (dst_clear_pending_r && dst_clear_done_internal)
      dst_clear_ack_r <= 1'b1;
    else if (!dst_clear_pending_r)
      dst_clear_ack_r <= 1'b0;
  end

  // Synchronize dst_clear_ack_r to src domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      dst_clear_ack_sync_r <= {SYNC_STAGES{1'b0}};
    else
      dst_clear_ack_sync_r <= {dst_clear_ack_sync_r[SYNC_STAGES-2:0], dst_clear_ack_r};
  end
  assign dst_clear_ack = dst_clear_ack_sync_r[SYNC_STAGES-1];

  // Source domain: clear done
  // src is done when: not in clear pending, or (in clear pending and dst has acknowledged)
  assign src_clear_done_internal = ~src_clear_pending_r | dst_clear_ack;

  // Destination domain: clear done
  // dst is done when: not in clear pending, or (in clear pending and src has acknowledged)
  assign dst_clear_done_internal = ~dst_clear_pending_r | src_clear_ack;

  // Source domain: valid/ready handshake
  // src_ready_internal is high when src is not holding a valid item
  assign src_ready_internal = ~src_valid_r;

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_r <= 1'b0;
      src_data_r <= {WIDTH{1'b0}};
    end else if (src_clear_active) begin
      src_valid_r <= 1'b0;
      src_data_r <= {WIDTH{1'b0}};
    end else if (src_valid_r && dst_ready_internal) begin
      // Handshake: transfer to dst
      src_valid_r <= 1'b0;
    end else if (!src_valid_r && src_valid_i && src_ready_internal) begin
      // Accept new data
      src_valid_r <= 1'b1;
      src_data_r <= src_data_i;
    end
  end

  // Destination domain: valid/ready handshake
  // dst_ready_internal is high when dst is not holding a valid item
  assign dst_ready_internal = ~dst_valid_r;

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_r <= 1'b0;
      dst_data_r <= {WIDTH{1'b0}};
    end else if (dst_clear_active) begin
      dst_valid_r <= 1'b0;
      dst_data_r <= {WIDTH{1'b0}};
    end else if (dst_valid_r && dst_ready_i) begin
      // Handshake: transfer to consumer
      dst_valid_r <= 1'b0;
    end else if (!dst_valid_r && src_valid_r) begin
      // Accept from src
      dst_valid_r <= 1'b1;
      dst_data_r <= src_data_r;
    end
  end

endmodule
