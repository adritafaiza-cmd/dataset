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
  wire src_clear_pending_int;
  wire dst_clear_pending_int;

  // Source domain: clear pending logic
  // When src_clear_i is asserted, we need to wait until the destination
  // has acknowledged the clear (dst_clear_synced) before deasserting pending.
  // Also, if CLEAR_ON_ASYNC_RESET is set, async reset also triggers clear.

  // Destination domain: clear pending logic
  // When dst_clear_i is asserted, we need to wait until the source
  // has acknowledged the clear (src_clear_synced) before deasserting pending.

  // We use a handshake for clear:
  // - src_clear_i or dst_clear_i initiates a clear
  // - The clear request is synchronized to the other domain
  // - The other domain acknowledges by clearing its local state
  // - Both sides deassert pending when they see the other side's clear has been processed

  // Let's define the clear protocol:
  // 1. Either src_clear_i or dst_clear_i goes high.
  // 2. The side that initiated the clear sets its pending high.
  // 3. The clear request is synchronized to the other domain.
  // 4. The other domain, upon seeing the synchronized clear, clears its local state
  //    and sets its pending high (if not already).
  // 5. Each side deasserts its pending when it sees the other side's pending has been
  //    deasserted (or when the clear is complete).

  // Actually, let's think more carefully. The clear is a coordinated flush.
  // Both sides need to know that the other side has finished clearing.

  // Let's use a simpler approach:
  // - src_clear_pending_o is high when src_clear_i is high OR when a clear is in progress
  //   initiated by dst_clear_i.
  // - dst_clear_pending_o is high when dst_clear_i is high OR when a clear is in progress
  //   initiated by src_clear_i.

  // The clear is complete when both sides have seen the other side's clear request
  // and have cleared their local state.

  // Let's define:
  // - src_clear_req: clear request from source side (src_clear_i or async reset if enabled)
  // - dst_clear_req: clear request from destination side (dst_clear_i or async reset if enabled)

  // Synchronize src_clear_req to dst domain: src_clear_synced
  // Synchronize dst_clear_req to src domain: dst_clear_synced

  // Source domain:
  // - src_clear_pending_o = src_clear_i | (dst_clear_synced & ~src_clear_done)
  //   where src_clear_done indicates that the source has finished clearing after a dst-initiated clear.

  // Destination domain:
  // - dst_clear_pending_o = dst_clear_i | (src_clear_synced & ~dst_clear_done)
  //   where dst_clear_done indicates that the destination has finished clearing after a src-initiated clear.

  // Let's implement this.

  // Source domain clear request
  wire src_clear_req = src_clear_i | (CLEAR_ON_ASYNC_RESET ? ~src_rst_ni : 1'b0);

  // Destination domain clear request
  wire dst_clear_req = dst_clear_i | (CLEAR_ON_ASYNC_RESET ? ~dst_rst_ni : 1'b0);

  // Synchronize src_clear_req to dst domain
  sync_stages #(
    .WIDTH(1),
    .STAGES(SYNC_STAGES)
  ) u_src_clear_sync (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .data_i(src_clear_req),
    .data_o(src_clear_synced)
  );

  // Synchronize dst_clear_req to src domain
  sync_stages #(
    .WIDTH(1),
    .STAGES(SYNC_STAGES)
  ) u_dst_clear_sync (
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .data_i(dst_clear_req),
    .data_o(dst_clear_synced)
  );

  // Source domain: track if we need to clear due to dst-initiated clear
  reg src_clear_from_dst;
  reg src_clear_done;

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_from_dst <= 1'b0;
      src_clear_done <= 1'b1;
    end else begin
      if (dst_clear_synced) begin
        src_clear_from_dst <= 1'b1;
        src_clear_done <= 1'b0;
      end else if (src_clear_from_dst && !dst_clear_synced) begin
        // dst_clear_synced has deasserted, meaning dst has finished clearing
        src_clear_done <= 1'b1;
        src_clear_from_dst <= 1'b0;
      end
    end
  end

  // Source clear pending: high when src_clear_i is high, or when dst-initiated clear is in progress
  assign src_clear_pending_o = src_clear_i | (src_clear_from_dst && !src_clear_done);

  // Destination domain: track if we need to clear due to src-initiated clear
  reg dst_clear_from_src;
  reg dst_clear_done;

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_from_src <= 1'b0;
      dst_clear_done <= 1'b1;
    end else begin
      if (src_clear_synced) begin
        dst_clear_from_src <= 1'b1;
        dst_clear_done <= 1'b0;
      end else if (dst_clear_from_src && !src_clear_synced) begin
        // src_clear_synced has deasserted, meaning src has finished clearing
        dst_clear_done <= 1'b1;
        dst_clear_from_src <= 1'b0;
      end
    end
  end

  // Destination clear pending: high when dst_clear_i is high, or when src-initiated clear is in progress
  assign dst_clear_pending_o = dst_clear_i | (dst_clear_from_src && !dst_clear_done);

  // Now implement the two-phase valid/ready channel with clear support.

  // Source domain:
  // - src_ready_o: high when the channel is not full and not in clear
  // - When src_valid_i && src_ready_o, accept the beat and transfer to dst domain

  // Destination domain:
  // - dst_valid_o: high when there is a pending beat
  // - When dst_valid_o && dst_ready_i, accept the beat and clear the pending state

  // The channel holds one outstanding item. We use a two-phase handshake:
  // - Phase 1: src sends data and valid to dst
  // - Phase 2: dst acknowledges and src can send next

  // Let's use a simple approach:
  // - src has a register to hold the data to send
  // - src_valid_o (internal) indicates that src has data to send
  // - dst has a register to hold the received data
  // - dst_valid_o indicates that dst has data to present

  // Actually, let's use a standard two-phase valid/ready:
  // - src_valid_i && src_ready_o: transfer occurs
  // - src_ready_o is high when the channel is empty (no outstanding item)
  // - dst_valid_o is high when there is an outstanding item
  // - dst_valid_o && dst_ready_i: item is consumed

  // The outstanding item is held in a register in the dst domain.
  // When src accepts a beat, it sets the dst domain's valid.
  // When dst consumes a beat, it clears the dst domain's valid.

  // We need to synchronize the valid signal from src to dst.
  // But we also need to handle clear.

  // Let's define:
  // - src_valid_reg: in src domain, indicates that src has sent a beat and is waiting for ack
  // - dst_valid_reg: in dst domain, indicates that dst has a pending beat

  // When src_valid_i && src_ready_o:
  //   - src_valid_reg <= 1
  //   - data is sent to dst domain

  // When dst_valid_reg && dst_ready_i:
  //   - dst_valid_reg <= 0
  //   - src_valid_reg is cleared (synchronized back to src domain)

  // src_ready_o = !src_valid_reg && !clear_active

  // Let's implement this.

  // Source domain
  reg src_valid_reg;
  reg [WIDTH-1:0] src_data_reg;

  // Synchronize src_valid_reg to dst domain
  wire src_valid_synced;
  sync_stages #(
    .WIDTH(1),
    .STAGES(SYNC_STAGES)
  ) u_src_valid_sync (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .data_i(src_valid_reg),
    .data_o(src_valid_synced)
  );

  // Synchronize src_data_reg to dst domain
  wire [WIDTH-1:0] src_data_synced;
  sync_stages #(
    .WIDTH(WIDTH),
    .STAGES(SYNC_STAGES)
  ) u_src_data_sync (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .data_i(src_data_reg),
    .data_o(src_data_synced)
  );

  // Synchronize dst_valid_reg to src domain (for ack)
  wire dst_valid_synced;
  sync_stages #(
    .WIDTH(1),
    .STAGES(SYNC_STAGES)
  ) u_dst_valid_sync (
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .data_i(dst_valid_reg),
    .data_o(dst_valid_synced)
  );

  // Destination domain
  reg dst_valid_reg;
  reg [WIDTH-1:0] dst_data_reg;

  // Clear active in src domain
  wire src_clear_active = src_clear_i | (src_clear_from_dst && !src_clear_done);

  // Clear active in dst domain
  wire dst_clear_active = dst_clear_i | (dst_clear_from_src && !dst_clear_done);

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
      src_data_reg <= {WIDTH{1'b0}};
    end else begin
      if (src_clear_active) begin
        src_valid_reg <= 1'b0;
        src_data_reg <= {WIDTH{1'b0}};
      end else if (src_valid_i && src_ready_o) begin
        src_valid_reg <= 1'b1;
        src_data_reg <= src_data_i;
      end else if (dst_valid_synced == 1'b0 && src_valid_reg == 1'b1) begin
        // dst has consumed the beat, clear src_valid_reg
        src_valid_reg <= 1'b0;
      end
    end
  end

  // src_ready_o: high when no outstanding item and not in clear
  assign src_ready_o = !src_valid_reg && !src_clear_active;

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
      dst_data_reg <= {WIDTH{1'b0}};
    end else begin
      if (dst_clear_active) begin
        dst_valid_reg <= 1'b0;
        dst_data_reg <= {WIDTH{1'b0}};
      end else if (src_valid_synced && !dst_valid_reg) begin
        // New beat from src
        dst_valid_reg <= 1'b1;
        dst_data_reg <= src_data_synced;
      end else if (dst_valid_reg && dst_ready_i) begin
        // Beat consumed
        dst_valid_reg <= 1'b0;
      end
    end
  end

  // Destination outputs
  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o = dst_data_reg;

endmodule

// Synchronization module
module sync_stages #(
  parameter WIDTH = 1,
  parameter STAGES = 2
)(
  input clk_i,
  input rst_ni,
  input [WIDTH-1:0] data_i,
  output [WIDTH-1:0] data_o
);
  reg [WIDTH-1:0] sync_reg [0:STAGES-1];

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (int i = 0; i < STAGES; i = i + 1) begin
        sync_reg[i] <= {WIDTH{1'b0}};
      end
    end else begin
      sync_reg[0] <= data_i;
      for (int i = 1; i < STAGES; i = i + 1) begin
        sync_reg[i] <= sync_reg[i-1];
      end
    end
  end

  assign data_o = sync_reg[STAGES-1];

endmodule
