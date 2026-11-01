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

  // Clear synchronization
  // Source clear to destination
  sync_ff #(SYNC_STAGES) src_clear_sync (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .data_i(src_clear_i),
    .data_o(src_clear_synced)
  );

  // Destination clear to source
  sync_ff #(SYNC_STAGES) dst_clear_sync (
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .data_i(dst_clear_i),
    .data_o(dst_clear_synced)
  );

  // Clear active logic
  // Source side: clear is active when src_clear_i is high OR dst_clear_synced is high
  // But we need to handle the coordinated flush properly.
  // Let's use a state machine approach for clear.

  // Source clear state
  reg src_clear_state;
  wire src_clear_req = src_clear_i | dst_clear_synced;
  
  // Destination clear state
  reg dst_clear_state;
  wire dst_clear_req = dst_clear_i | src_clear_synced;

  // Source clear pending: high when clear is in progress
  // Clear is in progress from when request is seen until both sides have acknowledged
  // For simplicity, let's define:
  // src_clear_pending_o is high when src_clear_i is high or when dst_clear_synced is high and we haven't finished
  // Actually, let's think about this more carefully.

  // The clear protocol:
  // 1. Either side asserts clear
  // 2. The clear request is synchronized to the other side
  // 3. Both sides isolate the channel (stop accepting new data, drop in-flight)
  // 4. Both sides return to idle
  // 5. Clear pending deasserts

  // Let's use a simple approach:
  // src_clear_pending_o is high when src_clear_i is high OR when dst_clear_synced is high
  // But we need to ensure it stays high until the clear is complete.

  // Actually, let's define clear pending as:
  // src_clear_pending_o = src_clear_i | (dst_clear_synced & ~src_clear_done)
  // dst_clear_pending_o = dst_clear_i | (src_clear_synced & ~dst_clear_done)

  // But we need to track when clear is done. Let's use a different approach.

  // Let's define:
  // src_clear_active = src_clear_i | dst_clear_synced
  // dst_clear_active = dst_clear_i | src_clear_synced

  // src_clear_pending_o is high when src_clear_active is high
  // dst_clear_pending_o is high when dst_clear_active is high

  // But we need to ensure that the clear is properly coordinated.
  // The key insight is that both sides must see the clear request before they can return to idle.

  // Let's use a handshake for clear:
  // When a clear is requested, both sides enter a clear state.
  // They exit the clear state when both sides have seen the clear request.

  // Source clear state machine
  reg src_clear_in_progress;
  wire src_clear_req_int = src_clear_i | dst_clear_synced;
  
  // Destination clear state machine
  reg dst_clear_in_progress;
  wire dst_clear_req_int = dst_clear_i | src_clear_synced;

  // Source clear in progress: set when clear request is seen, cleared when both sides have seen it
  // For source: clear is in progress when src_clear_req_int is high
  // But we need to ensure it stays high until dst has also seen it.
  // Actually, dst_clear_synced is the synchronized version of dst_clear_i, so if dst_clear_i is high,
  // src will see it after SYNC_STAGES cycles. Similarly, src_clear_i is seen by dst after SYNC_STAGES cycles.

  // Let's define:
  // src_clear_pending_o = src_clear_i | dst_clear_synced
  // dst_clear_pending_o = dst_clear_i | src_clear_synced

  // This ensures that clear pending is high as long as either side has requested clear.
  // The clear is complete when both src_clear_i and dst_clear_i are low, and the synchronized versions are also low.

  assign src_clear_pending_o = src_clear_i | dst_clear_synced;
  assign dst_clear_pending_o = dst_clear_i | src_clear_synced;

  // Clear active: when clear is in progress, the channel is isolated
  wire src_clear_active = src_clear_pending_o;
  wire dst_clear_active = dst_clear_pending_o;

  // Data path: source to destination
  // We need to transfer data from src to dst across the clock domain.
  // Since we can hold one outstanding item, we can use a simple approach:
  // - When src_valid_i and src_ready_o are both high, the data is accepted.
  // - The data is then transferred to the destination domain.
  // - dst_valid_o is high when there is data to be consumed.
  // - When dst_valid_o and dst_ready_i are both high, the data is consumed.

  // For the data transfer, we need to synchronize the data and valid signals.
  // Since the data can change when a new beat is accepted, we need to be careful.

  // Let's use a simple approach:
  // - src_data_reg holds the data to be transferred.
  // - src_valid_reg indicates that there is data to be transferred.
  // - When src_valid_i and src_ready_o are high, src_data_reg is updated with src_data_i, and src_valid_reg is set.
  // - src_valid_reg is cleared when dst_valid_o and dst_ready_i are high (data consumed).
  // - dst_valid_o is the synchronized version of src_valid_reg.
  // - dst_data_o is the synchronized version of src_data_reg.

  // But we need to handle the clear case: when clear is active, we drop in-flight data.

  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;

  // Source ready: high when we can accept new data
  // We can accept new data when:
  // 1. Clear is not active
  // 2. There is no outstanding data (src_valid_reg is low)
  assign src_ready_o = ~src_clear_active & ~src_valid_reg;

  // Update src_data_reg and src_valid_reg
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
    end else if (src_clear_active) begin
      // Drop in-flight data
      src_valid_reg <= 1'b0;
    end else if (src_valid_i & src_ready_o) begin
      src_data_reg <= src_data_i;
      src_valid_reg <= 1'b1;
    end else if (dst_valid_o & dst_ready_i) begin
      // Data consumed, clear valid
      src_valid_reg <= 1'b0;
    end
  end

  // Synchronize src_valid_reg to destination
  sync_ff #(SYNC_STAGES) src_valid_sync (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .data_i(src_valid_reg),
    .data_o(dst_valid_o)
  );

  // Synchronize src_data_reg to destination
  // We need to synchronize the data as well. Since the data can change, we need to be careful.
  // One approach is to use a multi-phase handshake, but for simplicity, let's assume that
  // the data is stable while src_valid_reg is high.
  // We can synchronize the data using a series of flip-flops.
  // But we need to ensure that the data is stable when it is sampled.

  // Let's use a simple approach: synchronize the data using SYNC_STAGES flip-flops.
  // The data is only valid when dst_valid_o is high, and at that point, the data should be stable.

  reg [WIDTH-1:0] dst_data_reg;
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= {WIDTH{1'b0}};
    end else if (dst_clear_active) begin
      // Drop in-flight data
      dst_data_reg <= {WIDTH{1'b0}};
    end else if (dst_valid_o & dst_ready_i) begin
      // Data consumed, but we don't need to clear dst_data_reg
    end else begin
      // Sample the data when it is valid
      // But we need to synchronize the data properly.
      // Let's use a different approach: synchronize the data using a series of flip-flops.
    end
  end

  // Actually, let's use a proper data synchronization approach.
  // We'll synchronize the data using SYNC_STAGES flip-flops, but we need to ensure
  // that the data is stable when it is sampled.

  // Let's use a different approach: use a handshake for data transfer.
  // But for simplicity, let's assume that the data is stable while src_valid_reg is high,
  // and we can synchronize it using a series of flip-flops.

  // Let's create a data synchronizer
  reg [WIDTH-1:0] data_sync [0:SYNC_STAGES-1];
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      for (int i = 0; i < SYNC_STAGES; i = i + 1) begin
        data_sync[i] <= {WIDTH{1'b0}};
      end
    end else if (dst_clear_active) begin
      for (int i = 0; i < SYNC_STAGES; i = i + 1) begin
        data_sync[i] <= {WIDTH{1'b0}};
      end
    end else begin
      data_sync[0] <= src_data_reg;
      for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
        data_sync[i] <= data_sync[i-1];
      end
    end
  end

  assign dst_data_o = data_sync[SYNC_STAGES-1];

  // Override dst_valid_o when clear is active
  wire dst_valid_int = dst_valid_o;
  assign dst_valid_o = dst_valid_int & ~dst_clear_active;

endmodule

// Synchronizer module
module sync_ff #(
  parameter STAGES = 3
)(
  input clk_i,
  input rst_ni,
  input data_i,
  output data_o
);
  reg [STAGES-1:0] sync_reg;
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      sync_reg <= {STAGES{1'b0}};
    end else begin
      sync_reg <= {sync_reg[STAGES-2:0], data_i};
    end
  end
  assign data_o = sync_reg[STAGES-1];
endmodule
