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

  // Source domain state
  reg src_valid_r;
  reg [WIDTH-1:0] src_data_r;

  // Destination domain state
  reg dst_valid_r;
  reg [WIDTH-1:0] dst_data_r;

  // Synchronizers for valid signal (2-stage)
  reg [1:0] valid_sync;

  // Synchronizers for ready signal (2-stage)
  reg [1:0] ready_sync;

  // Source domain: ready is high when no valid item is pending
  assign src_ready_o = ~src_valid_r;

  // Source domain: capture data and valid when handshake occurs
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_r <= 1'b0;
      src_data_r  <= {WIDTH{1'b0}};
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_valid_r <= 1'b1;
        src_data_r  <= src_data_i;
      end else if (valid_sync[1]) begin
        // Destination has consumed the item
        src_valid_r <= 1'b0;
      end
    end
  end

  // Synchronize src_valid_r to destination domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      valid_sync <= 2'b00;
    end else begin
      valid_sync <= {valid_sync[0], src_valid_r};
    end
  end

  // Destination domain: valid is high when synchronized valid is high
  assign dst_valid_o = valid_sync[1];

  // Destination domain: capture data when valid is asserted
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_r <= {WIDTH{1'b0}};
    end else begin
      if (valid_sync[1] && !dst_valid_r) begin
        // First cycle of valid assertion: capture data
        dst_data_r <= src_data_r;
      end
    end
  end

  // Destination domain: track valid state
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_r <= 1'b0;
    end else begin
      if (valid_sync[1]) begin
        dst_valid_r <= 1'b1;
      end else if (dst_valid_r && dst_ready_i) begin
        dst_valid_r <= 1'b0;
      end
    end
  end

  assign dst_data_o = dst_data_r;

  // Synchronize dst_ready to source domain
  // We need to tell source when destination is ready to accept next item
  // dst_ready_sync is high when destination is not holding a valid item
  // i.e., when dst_valid_r is low

  // Actually, let's think about this differently.
  // The source should be ready when it has no pending valid item.
  // src_ready_o = ~src_valid_r already handles this.
  // But we need to ensure that when src_valid_r is cleared, it's because
  // the destination has actually consumed the item.

  // Let me reconsider the architecture. The issue is that src_valid_r is
  // cleared based on valid_sync[1], but valid_sync[1] is the synchronized
  // version of src_valid_r itself. This creates a feedback loop.

  // Let me redesign:
  // Use a simple 2-phase handshake with proper CDC.

  // Actually, let me use a different approach:
  // - Source holds data and asserts a "data_valid" signal
  // - This signal is synchronized to destination
  // - Destination captures data when it sees the synchronized valid
  // - Destination asserts a "data_consumed" signal when it's done
  // - This signal is synchronized back to source
  // - Source clears its valid when it sees the synchronized consumed

  // Let me redo this properly.

  // Source domain
  reg src_valid_r;
  reg [WIDTH-1:0] src_data_r;

  // Destination domain
  reg dst_valid_r;
  reg [WIDTH-1:0] dst_data_r;

  // Synchronizer: src_valid -> dst domain
  reg [1:0] valid_sync;

  // Synchronizer: dst_consumed -> src domain
  reg [1:0] consumed_sync;

  // Source ready: high when no valid item pending
  assign src_ready_o = ~src_valid_r;

  // Source: capture on handshake
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_r <= 1'b0;
      src_data_r  <= {WIDTH{1'b0}};
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_valid_r <= 1'b1;
        src_data_r  <= src_data_i;
      end else if (consumed_sync[1]) begin
        src_valid_r <= 1'b0;
      end
    end
  end

  // Synchronize src_valid_r to dst domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      valid_sync <= 2'b00;
    end else begin
      valid_sync <= {valid_sync[0], src_valid_r};
    end
  end

  // Destination: valid output
  assign dst_valid_o = valid_sync[1];

  // Destination: capture data when valid first asserted
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_r <= {WIDTH{1'b0}};
    end else begin
      if (valid_sync[1] && !dst_valid_r) begin
        dst_data_r <= src_data_r;
      end
    end
  end

  // Destination: track valid
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_r <= 1'b0;
    end else begin
      if (valid_sync[1]) begin
        dst_valid_r <= 1'b1;
      end else if (dst_valid_r && dst_ready_i) begin
        dst_valid_r <= 1'b0;
      end
    end
  end

  assign dst_data_o = dst_data_r;

  // Destination: assert consumed when valid is deasserted
  // consumed is high when dst_valid_r is low and we had a valid item
  // Actually, consumed should be a pulse or level that tells source
  // that the item has been consumed.

  // Let's use: consumed = ~dst_valid_r && valid_sync[1] is not right.
  // consumed should be high when the destination has finished with the item.
  // That is when dst_valid_r goes from 1 to 0.

  // Let me use a different signal: dst_done
  // dst_done is high when dst_valid_r is low (no item pending in dst)
  // But we need to distinguish between "never had an item" and "consumed an item"

  // Simpler: consumed_sync should reflect whether the destination has
  // consumed the current item. Let's define:
  // dst_consumed = ~dst_valid_r
  // But this is high at reset too, which would clear src_valid_r incorrectly.

  // Better: use a pulse. When dst_valid_r transitions from 1 to 0,
  // generate a pulse that is synchronized back.

  reg dst_consumed_pulse;

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_consumed_pulse <= 1'b0;
    end else begin
      dst_consumed_pulse <= (dst_valid_r && !dst_ready_i) ? 1'b0 :
                             (dst_valid_r && dst_ready_i) ? 1'b1 : 1'b0;
    end
  end

  // Hmm, this is getting complicated. Let me use a cleaner approach.

  // Use a 2-phase handshake with explicit request/ack.

  // Source: req is high when it has data to send
  // Destination: ack is high when it has consumed the data

  // req is synchronized to dst, ack is synchronized to src.

  // Let me restart with a clean design.

  // Source domain
  reg src_valid_r;
  reg [WIDTH-1:0] src_data_r;

  // Destination domain
  reg dst_valid_r;
  reg [WIDTH-1:0] dst_data_r;

  // Synchronizers
  reg [1:0] valid_sync;   // src_valid_r -> dst
  reg [1:0] ack_sync;     // dst_ack -> src

  // Source ready
  assign src_ready_o = ~src_valid_r;

  // Source: capture data
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_r <= 1'b0;
      src_data_r  <= {WIDTH{1'b0}};
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_valid_r <= 1'b1;
        src_data_r  <= src_data_i;
      end else if (ack_sync[1]) begin
        src_valid_r <= 1'b0;
      end
    end
  end

  // Synchronize src_valid_r
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      valid_sync <= 2'b00;
    end else begin
      valid_sync <= {valid_sync[0], src_valid_r};
    end
  end

  // Destination valid
  assign dst_valid_o = valid_sync[1];

  // Destination: capture data
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_r <= {WIDTH{1'b0}};
    end else begin
      if (valid_sync[1] && !dst_valid_r) begin
        dst_data_r <= src_data_r;
      end
    end
  end

  // Destination: track valid
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_r <= 1'b0;
    end else begin
      if (valid_sync[1]) begin
        dst_valid_r <= 1'b1;
      end else if (dst_valid_r && dst_ready_i) begin
        dst_valid_r <= 1'b0;
      end
    end
  end

  assign dst_data_o = dst_data_r;

  // Destination: ack is high when dst_valid_r is low
  // But we need to be careful: ack should only be high after a valid item
  // has been consumed, not at reset.

  // Let's use: ack = ~dst_valid_r
  // At reset, dst_valid_r is 0, so ack is 1. This would clear src_valid_r
  // at reset, which is fine since src_valid_r is also 0 at reset.

  // But there's a race: if src_valid_r is 1 and dst_valid_r is 0 (because
  // the item hasn't been synchronized yet), ack would be 1 and src_valid_r
  // would be cleared prematurely.

  // So we need a different approach. Let's use a 2-phase handshake where
  // ack is a pulse.

  // Actually, the standard approach for this is to use a FIFO or a
  // proper handshake. Let me use a simpler method:

  // The key insight: src_valid_r should only be cleared when the destination
  // has actually consumed the item. The destination consumes the item when
  // dst_valid_o && dst_ready_i.

  // So let's synchronize the "consumed" event back to the source.

  reg dst_consumed;

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_consumed <= 1'b0;
    end else begin
      if (dst_valid_r && dst_ready_i) begin
        dst_consumed <= 1'b1;
      end else if (dst_consumed && !dst_valid_r) begin
        dst_consumed <= 1'b0;
      end
    end
  end

  // Synchronize dst_consumed to src domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      ack_sync <= 2'b00;
    end else begin
      ack_sync <= {ack_sync[0], dst_consumed};
    end
  end

endmodule
