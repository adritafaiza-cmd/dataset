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

  // Clear synchronization: src_clear_i -> dst domain
  wire [SYNC_STAGES-1:0] src_clear_sync_reg;
  assign src_clear_synced = src_clear_sync_reg[SYNC_STAGES-1];

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_clear_sync_reg <= '0;
    end else begin
      src_clear_sync_reg <= {src_clear_sync_reg[SYNC_STAGES-2:0], src_clear_i};
    end
  end

  // Clear synchronization: dst_clear_i -> src domain
  wire [SYNC_STAGES-1:0] dst_clear_sync_reg;
  assign dst_clear_synced = dst_clear_sync_reg[SYNC_STAGES-1];

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_clear_sync_reg <= '0;
    end else begin
      dst_clear_sync_reg <= {dst_clear_sync_reg[SYNC_STAGES-2:0], dst_clear_i};
    end
  end

  // Clear active in each domain
  assign src_clear_active = src_clear_i | dst_clear_synced;
  assign dst_clear_active = dst_clear_i | src_clear_synced;

  // Clear done: when the local clear request is deasserted and the remote clear has been synchronized
  // For src: clear is done when src_clear_i is low and dst_clear_synced is low
  // For dst: clear is done when dst_clear_i is low and src_clear_synced is low
  assign src_clear_done = !src_clear_i && !dst_clear_synced;
  assign dst_clear_done = !dst_clear_i && !src_clear_synced;

  // Clear pending: high until clear is done
  // During reset, clear pending should be low (or high depending on interpretation)
  // Let's say clear pending is high when a clear is in progress
  // A clear is in progress if either local or remote clear is active
  // But we need to track state properly

  // Let's use a state machine approach for clear
  // src_clear_pending_o: high from when clear is requested until both sides are idle
  // dst_clear_pending_o: same

  // Actually, let's think about this more carefully.
  // src_clear_pending_o should be high while the source side is in the process of clearing
  // dst_clear_pending_o should be high while the destination side is in the process of clearing

  // The clear process:
  // 1. A clear is requested (either src_clear_i or dst_clear_i goes high)
  // 2. The clear propagates to the other domain via synchronization
  // 3. Both sides drop any in-flight data
  // 4. Both sides return to idle
  // 5. Clear pending deasserts

  // Let's track clear state in each domain
  reg src_clear_pending_reg;
  reg dst_clear_pending_reg;

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pending_reg <= 1'b0;
    end else if (src_clear_active) begin
      src_clear_pending_reg <= 1'b1;
    end else if (src_clear_pending_reg && src_clear_done) begin
      src_clear_pending_reg <= 1'b0;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pending_reg <= 1'b0;
    end else if (dst_clear_active) begin
      dst_clear_pending_reg <= 1'b1;
    end else if (dst_clear_pending_reg && dst_clear_done) begin
      dst_clear_pending_reg <= 1'b0;
    end
  end

  assign src_clear_pending_o = src_clear_pending_reg;
  assign dst_clear_pending_o = dst_clear_pending_reg;

  // Handshake signals
  // src_ready_o: source can accept new data
  // dst_valid_o: destination has valid data
  // dst_ready_i: destination is ready to accept data

  // We need a simple 2-phase handshake with clear support
  // The channel holds one outstanding item
  // src_ready_o is high when the channel is empty and not in clear
  // dst_valid_o is high when the channel has data and not in clear

  reg src_has_data;
  reg [WIDTH-1:0] src_data_reg;
  reg dst_has_data;
  reg [WIDTH-1:0] dst_data_reg;

  // Source side: accept data when ready
  wire src_accept = src_valid_i && src_ready_o && !src_clear_active;

  // Destination side: accept data when ready
  wire dst_accept = dst_valid_o && dst_ready_i && !dst_clear_active;

  // We need to synchronize the data and valid signals across clock domains
  // Since we have a single outstanding item, we can use a simple approach:
  // When source accepts data, it sets a flag that is synchronized to destination
  // When destination accepts data, it clears the flag

  // Let's use a 2-phase handshake with synchronization
  // src_valid_synced: synchronized version of src_valid to dst domain
  // dst_ready_synced: synchronized version of dst_ready to src domain

  // Actually, for a single-item channel, we can use a simpler approach:
  // The source holds data until the destination acknowledges
  // We need to synchronize the "data available" signal and the "data consumed" signal

  // Let's use a 2-phase handshake:
  // Phase 1: Source asserts valid, destination sees it after sync
  // Phase 2: Destination asserts ready (ack), source sees it after sync and deasserts valid

  // But with clear, we need to handle the case where clear happens during transfer

  // Let's use a different approach:
  // The channel has a single buffer
  // src_ready_o = !src_has_data && !src_clear_active
  // dst_valid_o = dst_has_data && !dst_clear_active
  // When src accepts: src_has_data <= 1, src_data_reg <= src_data_i
  // When dst accepts: dst_has_data <= 0, dst_data_reg <= 0 (or keep)
  // We need to synchronize src_has_data to dst domain and dst_has_data to src domain

  // But we need to be careful about the timing

  // Let's use a 2-phase handshake with explicit synchronization
  // src_to_dst_valid: synchronized from src to dst
  // dst_to_src_ready: synchronized from dst to src

  reg src_to_dst_valid;
  reg [WIDTH-1:0] src_to_dst_data;
  reg dst_to_src_ready;

  // Synchronize src_to_dst_valid to dst domain
  wire [SYNC_STAGES-1:0] src_to_dst_valid_sync;
  assign src_to_dst_valid_sync[0] = src_to_dst_valid;
  genvar i;
  generate
    for (i = 1; i < SYNC_STAGES; i = i + 1) begin : gen_valid_sync
      always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
          src_to_dst_valid_sync[i] <= 1'b0;
        end else begin
          src_to_dst_valid_sync[i] <= src_to_dst_valid_sync[i-1];
        end
      end
    end
  endgenerate
  wire dst_sees_valid = src_to_dst_valid_sync[SYNC_STAGES-1];

  // Synchronize dst_to_src_ready to src domain
  wire [SYNC_STAGES-1:0] dst_to_src_ready_sync;
  assign dst_to_src_ready_sync[0] = dst_to_src_ready;
  generate
    for (i = 1; i < SYNC_STAGES; i = i + 1) begin : gen_ready_sync
      always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
          dst_to_src_ready_sync[i] <= 1'b0;
        end else begin
          dst_to_src_ready_sync[i] <= dst_to_src_ready_sync[i-1];
        end
      end
    end
  endgenerate
  wire src_sees_ready = dst_to_src_ready_sync[SYNC_STAGES-1];

  // Synchronize data: we need to ensure data is stable when valid is asserted
  // Since we only change data when valid is deasserted, and valid is synchronized,
  // we can synchronize data along with valid
  // But multi-bit data needs to be stable during the sync period
  // We'll use a data register that is only updated when valid is low

  // For data synchronization, we'll use a simple approach:
  // Data is captured in src domain when src accepts
  // Data is synchronized to dst domain using a multi-bit synchronizer
  // But multi-bit synchronizers are tricky. Instead, we'll use the fact that
  // data is stable while valid is high, and we can use a simple register in dst domain
  // that captures data when dst_sees_valid transitions from 0 to 1

  // Actually, let's use a different approach:
  // We'll use a 2-phase handshake where the data is transferred along with the valid signal
  // The data is stable in the src domain while src_to_dst_valid is high
  // In the dst domain, we capture the data when dst_sees_valid goes high

  // But we need to ensure the data is stable during the synchronization delay
  // Since the data is only changed when src_to_dst_valid is low, and the synchronization
  // delay is fixed, the data should be stable during the sync period

  // Let's use a data register in dst domain that is updated when dst_sees_valid rises
  reg [WIDTH-1:0] dst_data_capture;
  reg dst_valid_seen;

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_seen <= 1'b0;
      dst_data_capture <= '0;
    end else if (dst_sees_valid && !dst_valid_seen) begin
      dst_valid_seen <= 1'b1;
      dst_data_capture <= src_to_dst_data;
    end else if (!dst_sees_valid) begin
      dst_valid_seen <= 1'b0;
    end
  end

  // But this doesn't work well because src_to_dst_data might not be stable
  // Let's use a different approach: synchronize the data using a multi-bit synchronizer
  // or use a handshake that ensures data stability

  // Actually, the simplest approach for a single-item channel is:
  // 1. Source holds data in a register
  // 2. Source asserts a "data available" signal
  // 3. Destination synchronizes the "data available" signal
  // 4. When destination sees "data available", it reads the data from a synchronized data register
  // 5. Destination asserts a "data consumed" signal
  // 6. Source synchronizes the "data consumed" signal and deasserts "data available"

  // For the data, we can use a simple register in the dst domain that is updated
  // when the source updates it, but we need to ensure coherence

  // Let's use a 2-phase handshake with data transfer:
  // The data is transferred in the same cycle as the valid signal
  // We'll use a data register in the dst domain that is updated when the valid signal
  // is synchronized and the data is stable

  // Actually, let's just use a simple approach:
  // The data is held in a register in the src domain
  // The data is synchronized to the dst domain using a multi-bit synchronizer
  // But multi-bit synchronizers require the data to be stable during the sync period

  // Since the data is only changed when the valid signal is low, and the valid signal
  // is synchronized, the data should be stable during the sync period

  // Let's use a data synchronizer:
  wire [WIDTH-1:0] src_to_dst_data_sync;
  genvar j;
  generate
    for (j = 0; j < WIDTH; j = j + 1) begin : gen_data_sync
      wire [SYNC_STAGES-1:0] data_bit_sync;
      assign data_bit_sync[0] = src_to_dst_data[j];
      for (i = 1; i < SYNC_STAGES; i = i + 1) begin : gen_data_bit_sync
        always @(posedge dst_clk_i or negedge dst_rst_ni) begin
          if (!dst_rst_ni) begin
            data_bit_sync[i] <= 1'b0;
          end else begin
            data_bit_sync[i] <= data_bit_sync[i-1];
          end
        end
      end
      assign src_to_dst_data_sync[j] = data_bit_sync[SYNC_STAGES-1];
    end
  endgenerate

  // Now, dst_valid_o is high when dst_sees_valid is high and the data is stable
  // But we need to ensure that the data is fully synchronized before presenting it

  // Let's use a simpler approach:
  // dst_valid_o = dst_sees_valid
  // dst_data_o = src_to_dst_data_sync
  // But this might not be coherent if the data changes during sync

  // Since the data is only changed when src_to_dst_valid is low, and the sync delay is fixed,
  // the data should be stable during the sync period

  // Let's go with this approach

  assign dst_valid_o = dst_sees_valid && !dst_clear_active;
  assign dst_data_o = src_to_dst_data_sync;

  // Source side logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_to_dst_valid <= 1'b0;
      src_to_dst_data <= '0;
    end else if (src_clear_active) begin
      src_to_dst_valid <= 1'b0;
      src_to_dst_data <= '0;
    end else if (src_valid_i && !src_to_dst_valid) begin
      src_to_dst_valid <= 1'b1;
      src_to_dst_data <= src_data_i;
    end else if (src_sees_ready && src_to_dst_valid) begin
      src_to_dst_valid <= 1'b0;
    end
  end

  // Destination side logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_to_src_ready <= 1'b0;
    end else if (dst_clear_active) begin
      dst_to_src_ready <= 1'b0;
    end else if (dst_sees_valid && dst_ready_i) begin
      dst_to_src_ready <= 1'b1;
    end else if (!dst_sees_valid) begin
      dst_to_src_ready <= 1'b0;
    end
  end

  // src_ready_o: source can accept new data
  assign src_ready_o = !src_to_dst_valid && !src_clear_active;

endmodule
