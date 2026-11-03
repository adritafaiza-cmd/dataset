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
  reg src_valid_reg;
  reg [WIDTH-1:0] src_data_reg;

  // Destination domain state
  reg dst_valid_reg;
  reg [WIDTH-1:0] dst_data_reg;

  // CDC synchronization signals
  // src_to_dst_valid: source indicates it has data to send
  // dst_to_src_ready: destination indicates it is ready to accept new data

  // Source to destination: valid signal (synchronized to dst domain)
  reg [2:0] src_valid_sync;
  wire src_valid_synced = src_valid_sync[2];

  // Destination to source: ready signal (synchronized to src domain)
  reg [2:0] dst_ready_sync;
  wire dst_ready_synced = dst_ready_sync[2];

  // Source domain logic
  // src_ready_o is high when source is not currently holding a valid item
  // that hasn't been acknowledged by destination, OR when destination is ready
  // to accept a new item.
  
  // The source can accept a new item when:
  // 1. It doesn't have a pending item (src_valid_reg is low), OR
  // 2. The destination has acknowledged the previous item (dst_ready_synced is high)
  
  // Actually, let's think about this more carefully.
  // We have a single outstanding item. The source holds data in src_data_reg
  // and asserts src_valid_reg when it has data to send.
  // The destination sees src_valid_synced and latches the data.
  // When the destination is ready to accept a new item, it asserts dst_ready_synced.
  
  // src_ready_o should be high when the source can accept a new item.
  // This is when either:
  // - There's no pending item (src_valid_reg is low), OR
  // - The destination has acknowledged the current item (dst_ready_synced is high)
  
  // But we need to be careful: if src_valid_reg is high and dst_ready_synced is high,
  // that means the destination has acknowledged the current item, so we can accept a new one.
  
  assign src_ready_o = ~src_valid_reg | dst_ready_synced;

  // Source domain: capture data when valid and ready
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
      src_data_reg  <= {WIDTH{1'b0}};
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_valid_reg <= 1'b1;
        src_data_reg  <= src_data_i;
      end else if (dst_ready_synced) begin
        // Destination has acknowledged, clear valid
        src_valid_reg <= 1'b0;
      end
    end
  end

  // Synchronize src_valid_reg to destination domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync <= 3'b000;
    end else begin
      src_valid_sync <= {src_valid_sync[1:0], src_valid_reg};
    end
  end

  // Destination domain logic
  // When src_valid_synced is high and dst_valid_reg is low, latch the data
  // and assert dst_valid_reg.
  // When dst_valid_reg is high and dst_ready_i is high, clear dst_valid_reg
  // and indicate readiness to source.
  
  // We need to track when the destination has acknowledged a transfer.
  // dst_ready_synced is used to tell the source that the destination is ready
  // to accept a new item.
  
  // Let's use a different approach:
  // dst_valid_reg is asserted when we have data to present to the destination.
  // When dst_valid_reg && dst_ready_i, the transfer completes.
  // After completion, we need to tell the source that we're ready for a new item.
  
  // The dst_ready_sync signal should be high when the destination is ready to
  // accept a new item from the source. This is when dst_valid_reg is low
  // (no pending item at destination).
  
  // But we need to be careful about the timing. Let's use a register to track
  // the ready state.
  
  reg dst_ready_reg;
  
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
      dst_data_reg  <= {WIDTH{1'b0}};
      dst_ready_reg <= 1'b1;
    end else begin
      if (dst_valid_reg && dst_ready_i) begin
        // Transfer complete, ready for new item
        dst_valid_reg <= 1'b0;
        dst_ready_reg <= 1'b1;
      end else if (!dst_valid_reg && src_valid_synced) begin
        // New item available from source, latch it
        dst_valid_reg <= 1'b1;
        dst_data_reg  <= src_data_reg;
        dst_ready_reg <= 1'b0;
      end else if (dst_valid_reg) begin
        // Still waiting for destination to be ready
        dst_ready_reg <= 1'b0;
      end
    end
  end

  // Synchronize dst_ready_reg to source domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_sync <= 3'b000;
    end else begin
      dst_ready_sync <= {dst_ready_sync[1:0], dst_ready_reg};
    end
  end

  // Outputs
  assign dst_data_o  = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
