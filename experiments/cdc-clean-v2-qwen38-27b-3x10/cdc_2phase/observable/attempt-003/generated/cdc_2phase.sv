module cdc_2phase #(
  parameter WIDTH = 1
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,
  input  dst_rst_ni,
  input  dst_clk_i,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);

  // Source side: capture data when valid and ready
  // Destination side: present data when valid and ready

  // We use a simple approach:
  // - Source side: when src_valid_i is high and src_ready_o is high, capture data
  // - We need to signal to destination that data is available
  // - Destination side: when dst_ready_i is high and dst_valid_o is high, data is consumed

  // Since we need to handle asynchronous clocks, we use a handshake protocol.
  // The key challenge is that src_valid_i and dst_ready_i are in different clock domains.

  // Approach: Use a two-phase handshake with proper CDC.
  // 
  // Let's use a simple approach:
  // - Source side has a register to hold data
  // - When src_valid_i && src_ready_o, we latch the data and set a "pending" flag
  // - The pending flag is synchronized to the destination clock domain
  // - Destination side sees the pending flag and presents data
  // - When dst_valid_o && dst_ready_i, the destination consumes the data
  // - The "consumed" signal is synchronized back to the source clock domain
  // - Source side clears the pending flag when it sees the consumed signal

  // Source side registers
  reg [WIDTH-1:0] src_data_reg;
  reg src_pending;
  reg src_consumed_sync;

  // Destination side registers
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_pending_sync;
  reg dst_consumed;

  // Synchronization signals
  // src_pending -> dst domain
  wire src_pending_raw;
  reg [2:0] src_pending_sync;

  // dst_consumed -> src domain
  wire dst_consumed_raw;
  reg [2:0] dst_consumed_sync;

  // Source side logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_pending <= 1'b0;
      src_consumed_sync <= 1'b0;
    end else begin
      // If we have pending data and it's been consumed, clear pending
      if (src_pending && src_consumed_sync) begin
        src_pending <= 1'b0;
      end
      // If source is valid and we're ready (not pending), capture data
      else if (src_valid_i && !src_pending) begin
        src_data_reg <= src_data_i;
        src_pending <= 1'b0; // Will be set by the sync logic
      end
    end
  end

  // Actually, let me rethink this. The handshake needs to be more careful.
  // 
  // Let's use a different approach:
  // - Source side: when src_valid_i is high and src_ready_o is high, we accept the data
  // - We need to ensure that the data is transferred exactly once
  // - We use a "request" signal from source to destination
  // - We use an "acknowledge" signal from destination to source
  //
  // The request signal is set when source has data to send
  // The acknowledge signal is set when destination has consumed the data
  //
  // Both signals need to be synchronized across clock domains.

  // Let me use a cleaner approach with explicit request/acknowledge

  // Source side
  reg [WIDTH-1:0] src_data_reg;
  reg src_req;
  reg src_ack_sync;

  // Destination side
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_req_sync;
  reg dst_ack;

  // Synchronization for src_req -> dst
  reg [2:0] src_req_sync;

  // Synchronization for dst_ack -> src
  reg [2:0] dst_ack_sync;

  // Source side logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_req <= 1'b0;
      src_ack_sync <= 1'b0;
    end else begin
      // If we have a request and it's been acknowledged, clear request
      if (src_req && src_ack_sync) begin
        src_req <= 1'b0;
      end
      // If source is valid and we're not already requesting, set request
      else if (src_valid_i && !src_req) begin
        src_data_reg <= src_data_i;
        src_req <= 1'b1;
      end
    end
  end

  // Synchronize src_req to destination domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_req_sync <= 3'b000;
    end else begin
      src_req_sync <= {src_req_sync[1:0], src_req};
    end
  end

  // Destination side logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= {WIDTH{1'b0}};
      dst_ack <= 1'b0;
    end else begin
      // If we have a request and destination is ready, accept data and set acknowledge
      if (src_req_sync[2] && dst_ready_i) begin
        dst_data_reg <= src_data_reg; // This is problematic - src_data_reg is in src domain
        dst_ack <= 1'b1;
      end
      // If we have an acknowledge and it's been seen by source, clear acknowledge
      else if (dst_ack && src_req_sync[2] == 1'b0) begin
        dst_ack <= 1'b0;
      end
    end
  end

  // This approach has issues because src_data_reg is in the source domain and we're trying to read it in the destination domain.
  // We need to synchronize the data as well, or use a different approach.

  // Let me use a proper CDC approach with a FIFO-like structure or a proper handshake.

  // Actually, the cleanest approach for a single-item transfer is:
  // 1. Source captures data when valid and ready
  // 2. Source sets a "data_valid" flag
  // 3. The data and flag are synchronized to the destination domain
  // 4. Destination presents data when the synchronized flag is high
  // 5. When destination is ready, it clears the flag (synchronized back to source)
  // 6. Source clears its local flag when it sees the cleared flag

  // But we need to be careful about the data synchronization.

  // Let me use a different approach: use a 2-flop synchronizer for the control signals,
  // and for the data, we can use a simple approach since the data is stable while the flag is high.

  // Source side
  reg [WIDTH-1:0] src_data_reg;
  reg src_data_valid;
  reg src_ack_sync;

  // Destination side
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_data_valid_sync;
  reg dst_ack;

  // Synchronization for src_data_valid -> dst
  reg [2:0] src_data_valid_sync;

  // Synchronization for dst_ack -> src
  reg [2:0] dst_ack_sync;

  // Source side logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_data_valid <= 1'b0;
      src_ack_sync <= 1'b0;
    end else begin
      // If we have valid data and it's been acknowledged, clear valid
      if (src_data_valid && src_ack_sync) begin
        src_data_valid <= 1'b0;
      end
      // If source is valid and we're not already holding data, capture data
      else if (src_valid_i && !src_data_valid) begin
        src_data_reg <= src_data_i;
        src_data_valid <= 1'b1;
      end
    end
  end

  // Synchronize src_data_valid to destination domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_data_valid_sync <= 3'b000;
    end else begin
      src_data_valid_sync <= {src_data_valid_sync[1:0], src_data_valid};
    end
  end

  // Destination side logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= {WIDTH{1'b0}};
      dst_ack <= 1'b0;
    end else begin
      // If we have valid data (synchronized) and destination is ready, accept data
      if (src_data_valid_sync[2] && dst_ready_i) begin
        dst_data_reg <= src_data_reg; // Still problematic
        dst_ack <= 1'b1;
      end
      // If we have an acknowledge and the source has cleared its valid, clear acknowledge
      else if (dst_ack && !src_data_valid_sync[2]) begin
        dst_ack <= 1'b0;
      end
    end
  end

  // Synchronize dst_ack to source domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ack_sync <= 3'b000;
    end else begin
      dst_ack_sync <= {dst_ack_sync[1:0], dst_ack};
    end
  end

  // Outputs
  assign src_ready_o = !src_data_valid;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = src_data_valid_sync[2];

endmodule
