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
  wire src_clear_synced;
  wire dst_clear_synced;
  wire src_clear_ack;
  wire dst_clear_ack;
  wire src_clear_req;
  wire dst_clear_req;

  // Source side clear pending
  reg src_clear_pending_r;
  assign src_clear_pending_o = src_clear_pending_r;

  // Destination side clear pending
  reg dst_clear_pending_r;
  assign dst_clear_pending_o = dst_clear_pending_r;

  // Source side: clear request generation
  // When src_clear_i is asserted, we need to send a clear request to dst
  // and wait for acknowledgment
  reg src_clear_req_r;
  assign src_clear_req = src_clear_req_r;

  // Destination side: clear request generation
  reg dst_clear_req_r;
  assign dst_clear_req = dst_clear_req_r;

  // Source side: clear acknowledge from destination
  reg src_clear_ack_r;
  assign src_clear_ack = src_clear_ack_r;

  // Destination side: clear acknowledge from source
  reg dst_clear_ack_r;
  assign dst_clear_ack = dst_clear_ack_r;

  // Source side: data and valid for the channel
  reg [WIDTH-1:0] src_data_r;
  reg src_valid_r;
  reg src_ready_r;

  // Destination side: data and valid for the channel
  reg [WIDTH-1:0] dst_data_r;
  reg dst_valid_r;
  reg dst_ready_r;

  // Source side: clear pending logic
  // When src_clear_i is asserted, set pending and send clear request
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pending_r <= 1'b0;
      src_clear_req_r     <= 1'b0;
      src_clear_ack_r     <= 1'b0;
    end else begin
      if (src_clear_i) begin
        src_clear_pending_r <= 1'b1;
        src_clear_req_r     <= 1'b1;
      end else if (src_clear_ack_r) begin
        src_clear_pending_r <= 1'b0;
        src_clear_req_r     <= 1'b0;
        src_clear_ack_r     <= 1'b0;
      end
    end
  end

  // Destination side: clear pending logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pending_r <= 1'b0;
      dst_clear_req_r     <= 1'b0;
      dst_clear_ack_r     <= 1'b0;
    end else begin
      if (dst_clear_i) begin
        dst_clear_pending_r <= 1'b1;
        dst_clear_req_r     <= 1'b1;
      end else if (dst_clear_ack_r) begin
        dst_clear_pending_r <= 1'b0;
        dst_clear_req_r     <= 1'b0;
      end
    end
  end

  // Source side: acknowledge destination's clear request
  // When dst_clear_req is seen (synchronized), acknowledge it
  // and clear any outstanding data
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_clear_ack_r <= 1'b0;
    end else begin
      if (dst_clear_synced) begin
        dst_clear_ack_r <= 1'b1;
      end else if (dst_clear_ack_r) begin
        dst_clear_ack_r <= 1'b0;
      end
    end
  end

  // Destination side: acknowledge source's clear request
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_clear_ack_r <= 1'b0;
    end else begin
      if (src_clear_synced) begin
        src_clear_ack_r <= 1'b1;
      end else if (src_clear_ack_r) begin
        src_clear_ack_r <= 1'b0;
      end
    end
  end

  // Source side: data and valid management
  // The source holds data while the receiver waits
  // During clear, both sides return to idle
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_r  <= {WIDTH{1'b0}};
      src_valid_r <= 1'b0;
      src_ready_r <= 1'b0;
    end else begin
      // If clear is pending or in progress, go to idle
      if (src_clear_pending_r || src_clear_req_r || dst_clear_synced) begin
        src_valid_r <= 1'b0;
        src_ready_r <= 1'b0;
      end else begin
        // Normal operation: accept data when valid and ready
        if (src_valid_i && src_ready_r) begin
          // Data was accepted, prepare for next
          src_valid_r <= 1'b0;
          src_ready_r <= 1'b0;
        end else if (src_valid_i && !src_ready_r) begin
          // Data is valid but not yet ready, hold it
          src_data_r  <= src_data_i;
          src_valid_r <= 1'b1;
          src_ready_r <= 1'b1;
        end else if (!src_valid_i && src_ready_r) begin
          // Ready but no valid data, go idle
          src_valid_r <= 1'b0;
          src_ready_r <= 1'b0;
        end
      end
    end
  end

  // Destination side: data and valid management
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_r  <= {WIDTH{1'b0}};
      dst_valid_r <= 1'b0;
      dst_ready_r <= 1'b0;
    end else begin
      // If clear is pending or in progress, go to idle
      if (dst_clear_pending_r || dst_clear_req_r || src_clear_synced) begin
        dst_valid_r <= 1'b0;
        dst_ready_r <= 1'b0;
      end else begin
        // Normal operation
        if (dst_valid_r && dst_ready_i) begin
          // Data was accepted, go idle
          dst_valid_r <= 1'b0;
          dst_ready_r <= 1'b0;
        end else if (!dst_valid_r && dst_ready_i) begin
          // Ready but no valid data, stay idle
          dst_valid_r <= 1'b0;
          dst_ready_r <= 1'b0;
        end
      end
    end
  end

  // Source ready output
  assign src_ready_o = src_ready_r;

  // Destination data and valid outputs
  assign dst_data_o  = dst_data_r;
  assign dst_valid_o = dst_valid_r;

  // Synchronization of clear signals
  // Source clear request to destination
  reg [SYNC_STAGES-1:0] src_clear_req_sync;
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_clear_req_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      src_clear_req_sync <= {src_clear_req_sync[SYNC_STAGES-2:0], src_clear_req};
    end
  end
  assign src_clear_synced = src_clear_req_sync[SYNC_STAGES-1];

  // Destination clear request to source
  reg [SYNC_STAGES-1:0] dst_clear_req_sync;
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_clear_req_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_clear_req_sync <= {dst_clear_req_sync[SYNC_STAGES-2:0], dst_clear_req};
    end
  end
  assign dst_clear_synced = dst_clear_req_sync[SYNC_STAGES-1];

  // Synchronization of clear acknowledge signals
  // Source clear acknowledge to destination
  reg [SYNC_STAGES-1:0] src_clear_ack_sync;
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_clear_ack_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      src_clear_ack_sync <= {src_clear_ack_sync[SYNC_STAGES-2:0], src_clear_ack};
    end
  end

  // Destination clear acknowledge to source
  reg [SYNC_STAGES-1:0] dst_clear_ack_sync;
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_clear_ack_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_clear_ack_sync <= {dst_clear_ack_sync[SYNC_STAGES-2:0], dst_clear_ack};
    end
  end

  // Data transfer from source to destination
  // Use a simple handshake: source presents data, destination accepts
  // The data is transferred when both sides agree

  // Source side: present data to destination
  // Destination side: accept data from source

  // We need to synchronize the data and valid signals
  // Use a two-phase handshake for data transfer

  // Source: data valid for transfer
  reg src_data_valid_r;
  reg [WIDTH-1:0] src_data_out_r;

  // Destination: data accepted
  reg dst_data_accepted_r;

  // Source side: data transfer logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_valid_r <= 1'b0;
      src_data_out_r   <= {WIDTH{1'b0}};
    end else begin
      if (src_clear_pending_r || src_clear_req_r || dst_clear_synced) begin
        src_data_valid_r <= 1'b0;
      end else if (src_valid_r && !src_data_valid_r) begin
        // Present data to destination
        src_data_valid_r <= 1'b1;
        src_data_out_r   <= src_data_r;
      end else if (src_data_valid_r && dst_data_accepted_r) begin
        // Data was accepted, clear valid
        src_data_valid_r <= 1'b0;
      end
    end
  end

  // Destination side: data acceptance logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_accepted_r <= 1'b0;
    end else begin
      if (dst_clear_pending_r || dst_clear_req_r || src_clear_synced) begin
        dst_data_accepted_r <= 1'b0;
      end else if (src_data_valid_synced && !dst_data_accepted_r && dst_ready_i) begin
        // Accept data
        dst_data_accepted_r <= 1'b1;
        dst_data_r          <= src_data_synced;
        dst_valid_r         <= 1'b1;
      end else if (dst_data_accepted_r) begin
        // Clear accepted flag
        dst_data_accepted_r <= 1'b0;
      end
    end
  end

  // Synchronize data valid and data from source to destination
  reg [SYNC_STAGES-1:0] src_data_valid_sync;
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_data_valid_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      src_data_valid_sync <= {src_data_valid_sync[SYNC_STAGES-2:0], src_data_valid_r};
    end
  end
  wire src_data_valid_synced = src_data_valid_sync[SYNC_STAGES-1];

  reg [WIDTH-1:0] src_data_sync;
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_data_sync <= {WIDTH{1'b0}};
    end else begin
      src_data_sync <= src_data_out_r;
    end
  end
  wire [WIDTH-1:0] src_data_synced = src_data_sync;

  // Synchronize data accepted from destination to source
  reg [SYNC_STAGES-1:0] dst_data_accepted_sync;
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_data_accepted_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_data_accepted_sync <= {dst_data_accepted_sync[SYNC_STAGES-2:0], dst_data_accepted_r};
    end
  end
  wire dst_data_accepted_synced = dst_data_accepted_sync[SYNC_STAGES-1];

  // Update source ready based on destination acceptance
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_r <= 1'b0;
    end else begin
      if (src_clear_pending_r || src_clear_req_r || dst_clear_synced) begin
        src_ready_r <= 1'b0;
      end else if (src_data_valid_r && dst_data_accepted_synced) begin
        // Data was accepted, ready for next
        src_ready_r <= 1'b1;
      end else if (!src_data_valid_r) begin
        // No data in flight, ready
        src_ready_r <= 1'b1;
      end
    end
  end

endmodule
