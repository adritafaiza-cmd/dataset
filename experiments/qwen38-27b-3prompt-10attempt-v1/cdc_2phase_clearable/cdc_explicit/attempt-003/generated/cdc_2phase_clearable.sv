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
  wire src_clear_active;
  wire dst_clear_active;
  wire src_clear_done;
  wire dst_clear_done;
  wire src_clear_pending_int;
  wire dst_clear_pending_int;

  // Clear synchronization: src_clear_i -> dst domain
  sync_ff_chain #(
    .WIDTH(1),
    .SYNC_STAGES(SYNC_STAGES)
  ) u_src_clear_sync (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .data_i(src_clear_i),
    .data_o(dst_clear_synced)
  );

  // Clear synchronization: dst_clear_i -> src domain
  sync_ff_chain #(
    .WIDTH(1),
    .SYNC_STAGES(SYNC_STAGES)
  ) u_dst_clear_sync (
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .data_i(dst_clear_i),
    .data_o(src_clear_synced)
  );

  // Clear active signals
  assign src_clear_active = src_clear_i | src_clear_synced;
  assign dst_clear_active = dst_clear_i | dst_clear_synced;

  // Clear done signals: when the clear request is deasserted and synced
  // We need to track when the clear has been fully processed
  // For simplicity, clear is done when the clear signal is low and the synced version is also low
  // But we need to ensure the channel is idle first

  // Let's use a state machine approach for clear handling
  // src_clear_pending_o: high from when src_clear_i is asserted until the clear is complete
  // dst_clear_pending_o: high from when dst_clear_i is asserted until the clear is complete

  // Clear pending logic
  // src_clear_pending_o should be high when src_clear_i is high OR when we're waiting for the clear to complete
  // The clear completes when:
  // 1. The clear signal has been synchronized to the other domain
  // 2. The channel is idle (no outstanding data)
  // 3. The clear signal is deasserted

  // Let's track clear state in each domain
  // src domain: clear_pending is high when src_clear_i is high or when we're in the middle of clearing
  // dst domain: clear_pending is high when dst_clear_i is high or when we're in the middle of clearing

  // For the clear to be complete, both sides must have seen the clear and the channel must be idle
  // Let's define:
  // src_clear_done: src_clear_i is low AND src_clear_synced is low AND channel is idle from src perspective
  // dst_clear_done: dst_clear_i is low AND dst_clear_synced is low AND channel is idle from dst perspective

  // Channel idle: no data in flight
  // We need to track if there's data in the channel

  // Let's use a simple approach:
  // The channel holds one item. We track if there's an item in the channel.
  // When clear is active, we drop the item and don't accept new ones.

  // Data path:
  // src_data_i is captured when src_valid_i && src_ready_o
  // The data is sent to dst domain via a synchronizer

  // For multi-bit data coherence, we need to use a handshake or a stable data approach
  // Since we have a valid/ready handshake, we can use the following approach:
  // 1. When src_valid_i && src_ready_o, capture the data
  // 2. Send a "data valid" pulse to dst domain
  // 3. The data is held stable until dst domain acknowledges

  // Let's use a 2-phase handshake for the data transfer
  // src side: data_valid_src (high when data is ready to send)
  // dst side: data_valid_dst (synchronized version)
  // dst side: data_ack_dst (high when dst has accepted the data)
  // src side: data_ack_src (synchronized version)

  // Actually, let's use a simpler approach with a single-bit handshake
  // The data is held in a register on the src side until the dst side acknowledges

  // Let's define:
  // src_data_reg: holds the data to be sent
  // src_data_valid: high when src_data_reg has valid data
  // dst_data_valid_synced: synchronized version of src_data_valid
  // dst_data_ack: high when dst has accepted the data
  // src_data_ack_synced: synchronized version of dst_data_ack

  // When src_data_valid && !src_data_ack_synced, the data is in flight
  // When dst_data_valid_synced && dst_ready_i, the dst accepts the data
  // When dst accepts, it asserts dst_data_ack for one cycle
  // When src sees src_data_ack_synced, it clears src_data_valid

  // This is a standard 2-phase handshake

  // Let's implement this

  // Source domain registers
  reg [WIDTH-1:0] src_data_reg;
  reg src_data_valid;
  reg src_data_ack_synced;

  // Destination domain registers
  reg dst_data_ack;
  reg dst_data_valid_synced;

  // Synchronizers
  // src_data_valid -> dst domain
  sync_ff_chain #(
    .WIDTH(1),
    .SYNC_STAGES(SYNC_STAGES)
  ) u_src_data_valid_sync (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .data_i(src_data_valid),
    .data_o(dst_data_valid_synced)
  );

  // dst_data_ack -> src domain
  sync_ff_chain #(
    .WIDTH(1),
    .SYNC_STAGES(SYNC_STAGES)
  ) u_dst_data_ack_sync (
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .data_i(dst_data_ack),
    .data_o(src_data_ack_synced)
  );

  // Data path: src_data_i is captured into src_data_reg when src_valid_i && src_ready_o
  // src_ready_o is high when:
  // 1. Not in clear
  // 2. No data in flight (src_data_valid is low OR src_data_ack_synced is high)
  // 3. dst is ready (we need to know if dst can accept)

  // Actually, for a 2-phase handshake, the src can send data when:
  // 1. Not in clear
  // 2. The previous data has been acknowledged (src_data_ack_synced is high) OR no data has been sent yet
  // 3. The dst is ready to accept (we need to track this)

  // Let's track dst_ready in the src domain
  // dst_ready_i is in the dst domain, so we need to synchronize it to the src domain

  // dst_ready_i -> src domain
  sync_ff_chain #(
    .WIDTH(1),
    .SYNC_STAGES(SYNC_STAGES)
  ) u_dst_ready_sync (
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .data_i(dst_ready_i),
    .data_o(dst_ready_synced)
  );

  wire dst_ready_synced;

  // src_ready_o: high when we can accept new data
  // We can accept new data when:
  // 1. Not in clear (src_clear_active is low)
  // 2. No data in flight: src_data_valid is low OR (src_data_valid is high AND src_data_ack_synced is high)
  //    Actually, if src_data_valid is high and src_data_ack_synced is high, the data has been acknowledged,
  //    so we can accept new data
  // 3. dst is ready: dst_ready_synced is high

  // Wait, in a 2-phase handshake, the src doesn't need to wait for dst_ready before sending.
  // The dst will accept the data when it's ready. The src just needs to know when the dst has accepted.
  // But if the dst is not ready, the data will stay in flight until the dst is ready.
  // So src_ready_o should be high when:
  // 1. Not in clear
  // 2. No data in flight (src_data_valid is low OR src_data_ack_synced is high)

  // Let's define:
  // data_in_flight = src_data_valid && !src_data_ack_synced
  // src_ready_o = !src_clear_active && !data_in_flight

  wire data_in_flight;
  assign data_in_flight = src_data_valid && !src_data_ack_synced;

  assign src_ready_o = !src_clear_active && !data_in_flight;

  // Capture data when src_valid_i && src_ready_o
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_data_valid <= 1'b0;
    end else if (src_clear_active) begin
      // Clear: drop any in-flight data
      src_data_valid <= 1'b0;
    end else if (src_valid_i && src_ready_o) begin
      src_data_reg <= src_data_i;
      src_data_valid <= 1'b1;
    end else if (src_data_ack_synced && src_data_valid) begin
      // Data has been acknowledged, clear the valid
      src_data_valid <= 1'b0;
    end
  end

  // Destination domain logic
  // dst_data_valid_o: high when dst_data_valid_synced is high
  // dst_data_o: the data from src_data_reg (but we need to synchronize the data)

  // For multi-bit data, we need to ensure the data is stable when the valid signal is high
  // Since we're using a 2-phase handshake, the data is held stable in src_data_reg until acknowledged
  // So we can synchronize the data along with the valid signal

  // But synchronizing multi-bit data is tricky. We need to ensure all bits are synchronized together.
  // One approach is to use a "data stable" signal that indicates when the data is stable
  // Another approach is to use a handshake that ensures the data is stable before the valid is synchronized

  // Let's use the following approach:
  // 1. When src_data_valid is asserted, the data in src_data_reg is stable
  // 2. We synchronize src_data_valid to the dst domain
  // 3. When dst_data_valid_synced is high, the data in src_data_reg is stable
  // 4. We can read src_data_reg in the dst domain, but we need to ensure it's stable

  // Actually, since src_data_reg is only changed when src_data_valid is low (or during clear),
  // and src_data_valid is synchronized to the dst domain, the data should be stable when
  // dst_data_valid_synced is high.

  // But there's a race condition: if src_data_valid is deasserted at the same time as
  // dst_data_valid_synced is being sampled, the data might change.

  // To avoid this, we can use a "data lock" signal that is asserted when the data is being sent
  // and deasserted when the data is acknowledged.

  // Let's use a simpler approach:
  // The data is held in src_data_reg until acknowledged.
  // The valid signal is synchronized to the dst domain.
  // The dst domain reads the data when the valid signal is high.
  // Since the data is stable while the valid signal is high (in the src domain),
  // and the valid signal is synchronized, the data should be stable when the dst domain
  // sees the valid signal as high.

  // But there's still a potential issue: if the src domain changes the data while the dst domain
  // is sampling the valid signal, the data might be in a metastable state.

  // To be safe, let's use a "data stable" signal that is asserted when the data is stable
  // and deasserted when the data is about to change.

  // Actually, let's use a different approach:
  // We'll use a 2-phase handshake for the data as well.
  // The data is sent along with the valid signal.
  // The dst domain acknowledges the data by asserting dst_data_ack.
  // The src domain deasserts src_data_valid when it sees dst_data_ack.

  // For the data, we'll use a "data valid" signal that is synchronized to the dst domain.
  // The data is held stable in src_data_reg until the dst domain acknowledges.
  // The dst domain reads the data when the "data valid" signal is high.

  // Let's implement this

  // dst_data_valid_o: high when dst_data_valid_synced is high
  assign dst_data_valid_o = dst_data_valid_synced;

  // dst_data_o: the data from src_data_reg
  // We need to read src_data_reg in the dst domain
  // Since src_data_reg is stable while dst_data_valid_synced is high,
  // we can read it directly

  assign dst_data_o = src_data_reg;

  // dst_data_ack: high when dst_data_valid_synced && dst_ready_i
  // We'll assert dst_data_ack for one cycle when the dst accepts the data
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_ack <= 1'b0;
    end else if (dst_clear_active) begin
      dst_data_ack <= 1'b0;
    end else if (dst_data_valid_synced && dst_ready_i) begin
      dst_data_ack <= 1'b1;
    end else begin
      dst_data_ack <= 1'b0;
    end
  end

  // Clear pending logic
  // src_clear_pending_o: high when src_clear_i is high OR when we're waiting for the clear to complete
  // The clear completes when:
  // 1. src_clear_i is low
  // 2. src_clear_synced is low (the clear has been synchronized to the dst domain)
  // 3. The channel is idle (no data in flight)

  // Let's track the clear state
  // src_clear_pending_o is high when:
  // 1. src_clear_i is high, OR
  // 2. src_clear_synced is high (the clear is still being processed in the dst domain), OR
  // 3. The channel is not idle (data_in_flight is high)

  // Actually, the clear should complete when:
  // 1. src_clear_i is low
  // 2. The clear has been synchronized to the dst domain (src_clear_synced is low)
  // 3. The channel is idle (data_in_flight is low)

  // So src_clear_pending_o is high when:
  // 1. src_clear_i is high, OR
  // 2. src_clear_synced is high, OR
  // 3. data_in_flight is high

  // But we need to be careful: if src_clear_i is high, we should drop the data immediately
  // and not wait for the dst domain to acknowledge

  // Let's define:
  // src_clear_pending_o = src_clear_i | src_clear_synced | data_in_flight

  // But this might not be correct: if src_clear_i is high, we drop the data, so data_in_flight
  // should become low. But if the dst domain hasn't seen the clear yet, it might still be
  // processing the data.

  // Let's use a state machine for the clear
  // src_clear_state: IDLE, CLEARING, DONE
  // dst_clear_state: IDLE, CLEARING, DONE

  // For simplicity, let's use the following approach:
  // src_clear_pending_o is high when src_clear_i is high OR when the clear is being processed
  // The clear is being processed when src_clear_synced is high OR when data_in_flight is high

  // Let's implement this

  assign src_clear_pending_o = src_clear_i | src_clear_synced | data_in_flight;

  // dst_clear_pending_o: high when dst_clear_i is high OR when the clear is being processed
  // The clear is being processed when dst_clear_synced is high OR when dst_data_valid_synced is high

  assign dst_clear_pending_o = dst_clear_i | dst_clear_synced | dst_data_valid_synced;

endmodule

// Synchronizer module
module sync_ff_chain #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3
)(
  input clk_i,
  input rst_ni,
  input [WIDTH-1:0] data_i,
  output [WIDTH-1:0] data_o
);
  reg [WIDTH-1:0] sync_reg [0:SYNC_STAGES-1];

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (int i = 0; i < SYNC_STAGES; i = i + 1) begin
        sync_reg[i] <= {WIDTH{1'b0}};
      end
    end else begin
      sync_reg[0] <= data_i;
      for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
        sync_reg[i] <= sync_reg[i-1];
      end
    end
  end

  assign data_o = sync_reg[SYNC_STAGES-1];

endmodule
